"""Turns a language course's authoring files into the flat pack source that `pack_builder build` signs.

    python tools/lang_pack.py eng            # one course (eng, heb or rus)
    python tools/lang_pack.py all            # the three courses
    python tools/lang_pack.py all --check    # writes nothing; exits 1 if the committed files differ from what the spec gives

A course is written by its teacher in two kinds of file (the format is in docs/languages/band-a-build.md):

    content/languages/<course>/course.json     the pack's id and version, the Hebrew lines, the feedback and hint ladders,
                                               the tags (the misconception catalogue) and the course defaults
    content/languages/<course>/units/*.json    one unit per skill (or a few): the skill, its items and its lessons
    content/languages/<course>/placement.json  the placement game (optional)
    docs/languages/<course>/pronunciation.csv  the clip table: every target-language clip an item plays

and this script writes, next to them:

    content/languages/<course>/pack/           the flat pack source (pack.json, skill.*, lesson.*, activity.*, misconception.*,
                                               placement.*, gate.*, the pictures it uses), committed like content/starter
    content/languages/<course>/voice-plan.json every clip the pack names, with its text, for the voice-and-sound-director

The script holds what is the same for every item of a kind (the file shape, the hint ladder, the scoring, the tutor switched off,
the voice ids); the teacher's files hold what only a teacher can decide. It checks what it can before the pack builder does, and says
every problem it finds at once. Pictures are copied from content/languages/pictures; nothing is voiced or paid here. Every Hebrew
text it writes is `needs-editor` until a person approves it. Standard library only.

The recipes of the templates (what a kind of item becomes: tap, listen and do, puppet talk, say it, chant, drum, story, count, pairs, sort,
trace, sequence, the own-name steps) are in tools/lang_recipes.py (class `Recipes`, which `Course` takes); this file reads, checks and
writes.
"""
import csv
import glob
import json
import os
import re
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
if TOOLS not in sys.path:  # `python -I` keeps the script's own folder off the path
    sys.path.insert(0, TOOLS)
import lang_recipes  # noqa: E402
import lang_routes  # noqa: E402

COURSES = ('eng', 'heb', 'rus')
DOMAIN = 'languages'
# The template versions the recipes write (app/lib/content/schemas.dart `supportedTemplates` must be at least these).
TEMPLATE_VERSIONS = {'tap_answer': '1.3', 'story': '1.0', 'listen_do': '1.0', 'sing_along': '1.0', 'puppet_talk': '1.0',
                     'sound_boxes': '1.0', 'count_tap': '1.1', 'sort_drag': '1.1', 'match_pairs': '1.1', 'build_pattern': '1.1',
                     'say_it': '1.0', 'trace': '1.0'}
REPRESENTATIONS = lang_recipes.REPRESENTATIONS
# The kinds of item a unit file may hold, and the recipe each one has (tools/lang_recipes*.py).
RECIPES = {'tap': 'tap', 'listen_do': 'listen_do', 'puppet': 'puppet', 'say': 'say', 'chant': 'chant', 'drum': 'drum', 'story': 'story',
           'count': 'count', 'pairs': 'pairs', 'sort': 'sort', 'sequence': 'sequence', 'trace': 'trace', 'name': 'name', 'name-letter': 'name_letter', 'page-zones': 'page_zones', 'follow': 'follow'}
TAG_KINDS = ('diagnostic', 'on_the_way', 'accent', 'practice')
FAMILIES = ('DIR', 'NAME', 'SHAPE', 'STROKE', 'CONTRAST', 'SEGMENT', 'RHYME', 'VOWEL', 'CODE', 'GRAMMAR', 'PRINT', 'GUESS',
            'MEANING', 'ACCENT', 'FLUENCY')
# What a skill file may carry beyond the fields the generator derives (frame section 3 and D-6 of docs/milestones/L0.md).
SKILL_EXTRAS = ('worldObject', 'childLine', 'core', 'bundle', 'setCoverage', 'soundRight', 'letters', 'writing', 'graphemes',
                'tricky', 'binary', 'masteryRequires')
VO_PART = re.compile(r'^[a-z0-9_.]{1,80}$')
ASSET_ID = re.compile(r'^[a-z0-9_]{1,40}$')
SKILL_ID = re.compile(r'^(ENG|HEB|RUS)-([ABC])-(\d{2})(\.[A-Z][0-9]{1,2})?$')
GATE_ID = re.compile(r'^[a-z]{3}\.[a-z0-9_]{1,19}$')  # content/schemas/gate.schema.json `id`
# The name of every file of the pack source: a plain name, no folder, no leading dot (a name is built from teacher text, so it is checked
# again where the files are written).
FILE_NAME = re.compile(r'^[A-Za-z0-9_][A-Za-z0-9_.-]{0,120}$')


class SpecError(Exception):
    """The course's files have problems; [problems] lists all of them."""

    def __init__(self, problems):
        super().__init__('\n'.join(problems))
        self.problems = problems


def he(text):
    """A Hebrew caption as the schemas hold it."""
    return [{'t': 'he', 'v': text}]


def slug(text):
    return re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')


class Course(lang_recipes.Recipes, lang_routes.Routes):
    """One course's spec, read and checked, and the files it makes."""

    def __init__(self, course, root=ROOT):
        self.id = course
        self.root = root
        self.dir = os.path.join(root, 'content', 'languages', course)
        self.problems = []
        self.files = {}  # name -> bytes, the pack source
        self.used_lines = set()
        self.used_clips = set()
        self.used_pictures = {}  # asset id -> picture file id
        self.skills = {}  # id -> skill info
        self.items = {}  # activity id (with the course) -> info
        self.groups = {}  # an item that makes two activities (a say step and its tap): its id -> [the activity ids, in order]
        self.cut_clips = {}  # the clip of a word cut from the clip of its page (follow): id -> {id, from, text}
        self.teach_count = 0  # the teach screens among self.items (they do not move the praise the other items say)
        self.derived = {}  # asset id -> how the generator makes the picture (a lit copy of a picture, a blank one)
        self.template_versions = TEMPLATE_VERSIONS
        self.lessons = []
        self._load()

    # ------------------------------------------------------------ reading
    def problem(self, where, message):
        text = '%s: %s' % (where, message)
        if text not in self.problems:
            self.problems.append(text)

    def _json(self, path):
        try:
            with open(path, encoding='utf-8') as fh:
                return json.load(fh)
        except (OSError, ValueError) as e:
            self.problem(os.path.relpath(path, self.root), 'cannot be read: %s' % e)
            return None

    def _load(self):
        self.spec = self._json(os.path.join(self.dir, 'course.json')) or {}
        if self.spec.get('course') != self.id:
            self.problem('course.json', 'course must be "%s"' % self.id)
        self.lines = self.spec.get('lines', {})
        for line_id in self.lines:
            if not re.match(r'^[a-z0-9][a-z0-9-]{0,60}$', line_id):
                self.problem('course.json lines', 'the id "%s" must be lower case letters, digits and hyphens' % line_id)
        self.tags = self.spec.get('tags', {})
        self.ladders = self.spec.get('ladders', {})
        self.glosses = self.spec.get('glosses', {})
        self.defaults = self.spec.get('defaults', {})
        self.pronunciation = {}
        csv_path = os.path.join(self.root, 'docs', 'languages', {'eng': 'english', 'heb': 'hebrew', 'rus': 'russian'}[self.id],
                                'pronunciation.csv')
        try:
            with open(csv_path, encoding='utf-8', newline='') as fh:
                self.pronunciation = {r['id']: r for r in csv.DictReader(fh)}
        except OSError as e:
            self.problem('pronunciation.csv', 'cannot be read: %s' % e)
        self.units = []
        for path in sorted(glob.glob(os.path.join(self.dir, 'units', '*.json'))):
            unit = self._json(path)
            if unit is not None:
                self.units.append((os.path.basename(path), unit))
        self.area_table = self._areas()
        self.stroke_scenes = self._stroke_scenes()
        self.placement = None
        placement = os.path.join(self.dir, 'placement.json')
        if os.path.exists(placement):
            self.placement = self._json(placement)

    def _areas(self):
        """The touch areas of the pictures (shares of the picture's side): scenes.areas.json, and the body map of mika-body (its parts,
        the close-up card of each part, and which items show their parts as cards)."""
        table = {}
        pictures = os.path.join(self.root, 'content', 'languages', 'pictures')
        path = os.path.join(pictures, 'scenes.areas.json')
        if os.path.exists(path):
            table = {k: dict(v) for k, v in (self._json(path) or {}).get('pictures', {}).items()}
        for path in sorted(glob.glob(os.path.join(pictures, '*.hotspots.json'))):
            data = self._json(path) or {}
            entry = table.setdefault(data.get('picture', os.path.basename(path).split('.')[0]), {})
            entry.update(data.get('parts', {}))
            entry['@cards'] = data.get('cards', {})
            entry['@items'] = data.get('items', {})
        return table

    def _stroke_scenes(self):
        """The paths of the pre-writing scenes (content/languages/strokes/prewriting-<course>-a14.json), by the scene's picture id."""
        path = os.path.join(self.root, 'content', 'languages', 'strokes', 'prewriting-%s-a14.json' % self.id)
        if not os.path.exists(path):
            return {}
        return {i['picture']: i for i in (self._json(path) or {}).get('items', [])}

    # ------------------------------------------------------------ ids and lines
    def vo(self, clip):
        """`vo:<course>.<id>`: the clip's id with its hyphens turned into underscores (the same id, as the voice plan lists it)."""
        ref = '%s.%s' % (self.id, clip.replace('-', '_'))
        if not VO_PART.match(ref) or len('vo:' + ref) > 83:
            self.problem(clip, 'is not a usable clip id (lower case letters, digits, hyphens; at most 77 characters)')
        return 'vo:' + ref

    def line_text(self, line_id, where):
        entry = self.lines.get(line_id)
        if not isinstance(entry, dict) or not isinstance(entry.get('he'), str) or not entry['he']:
            self.problem(where, 'the line "%s" is not in course.json "lines" (it needs "he", the Hebrew with nikud)' % line_id)
            return None
        return entry['he']

    def clip_row(self, clip, where):
        row = self.pronunciation.get(clip)
        if row is None:
            self.problem(where, 'the clip "%s" has no row in docs/languages/%s/pronunciation.csv' % (clip, self.id))
        return row

    def spoken(self, step, where, item=None):
        """A Spoken (vo, caption, optional target and show) from a step: a line id, or {"line", "target", "show"}.

        A target is a clip id, or `@target` (the item's own word) or `@slow` (its slow clip if there is one). A line is a line id, or
        `@frame` (the item's own question) or `@gloss` (the line that says what the word means, from "glosses")."""
        if isinstance(step, str):
            step = {'line': step}
        line_id = self.resolve_line(step.get('line'), item, where, step.get('orLine'))
        if line_id is None:
            return None
        text = self.line_text(line_id, where)
        if text is None:
            return None
        self.used_lines.add(line_id)
        out = {'vo': self.vo(line_id), 'caption': he(text)}
        target = self.resolve_target(step.get('target'), item, where)
        if target:
            out['target'] = self.vo(target)
            self.used_clips.add(target)
            self.clip_row(target, where)
            if step.get('show'):
                row = self.clip_row(target, where)
                if row and row.get('shown'):
                    # A word on show stands alone in its chip: no full stop, question mark or exclamation mark beside it.
                    out['show'] = row['shown'].rstrip(' .!?,')
            second = self.resolve_target(step.get('target2'), item, where)
            if second:
                out['target2'] = self.vo(second)
                self.used_clips.add(second)
                self.clip_row(second, where)
        elif step.get('target2'):
            self.problem(where, 'a line with a second target clip has a first one')
        return out

    @staticmethod
    def word_of(item):
        """The clip a hint or a praise names as "the word" of the item: `hintWord` when the prompt must not say it (a story's pause, a
        bubble), else the clip the prompt plays."""
        return (item or {}).get('hintWord') or (item or {}).get('target')

    def resolve_line(self, line, item, where, or_line=None):
        if line == '@frame':
            line = (item or {}).get('frame') or self.defaults.get('frame')
        if line == '@gloss':
            clip = self.word_of(item)
            line = (item or {}).get('h2') or self.glosses.get(clip)
            if not line and or_line:
                line = or_line  # a first language has no gloss: the step says its other line
            elif not line:
                self.problem(where, 'the ladder asks for a gloss, and course.json "glosses" has none for "%s"' % clip)
        return line

    def resolve_target(self, target, item, where):
        if not target:
            return None
        own = self.word_of(item)
        if target == '@target':
            return own
        if target == '@slow':
            return own + '-slow' if own and own + '-slow' in self.pronunciation else own
        if target == '@target2':
            return (item or {}).get('target2')
        if target.startswith('@'):
            self.problem(where, 'unknown target "%s"' % target)
            return None
        return target

    # ------------------------------------------------------------ building
    def build(self):
        self._tags_used = {}
        self._skill_reps = {}
        self.assets = {}
        self.groups = {}
        self.derived = {}
        for name, unit in self.units:
            self._unit(name, unit)
        self._lessons()
        self._skills()
        self._tag_docs()
        self._placement()
        self._pack_json()
        self._voice_plan()
        if self.problems:
            raise SpecError(self.problems)
        return self.files

    def put(self, name, doc):
        self.files[name] = (json.dumps(doc, ensure_ascii=False, indent=2) + '\n').encode('utf-8')

    # ---- units, skills and items
    def _unit(self, fname, unit):
        skill = unit.get('skill', {})
        sid = skill.get('id', '')
        m = SKILL_ID.fullmatch(sid)
        if not m or m.group(1) != self.id.upper():
            self.problem(fname, 'skill.id "%s" must look like %s-A-01 (the prefix is the course in capitals)' % (sid, self.id.upper()))
            return
        if sid in self.skills:
            self.problem(fname, 'the skill %s is defined twice' % sid)
        sk = {'doc': skill, 'file': fname, 'band': m.group(2), 'slug': (m.group(2) + m.group(3) + (m.group(4) or '')).lower(),
              'items': [], 'ownName': unit.get('ownName')}
        self.skills[sid] = sk
        # The routes come first: the say steps are made by the order the unit's routes give them.
        self.check_routes(fname, unit)
        sk['routes'] = unit.get('routes') if isinstance(unit.get('routes'), dict) else None
        for i, item in enumerate(unit.get('items', [])):
            self._item(fname, sk, sid, item, '%s items[%d]' % (fname, i))
        for i, doc in enumerate(unit.get('docs', [])):
            self._raw(fname, doc, '%s docs[%d]' % (fname, i))
        self.teach_items(fname, sk, sid, unit)
        sk['lessons'] = unit.get('lessons', [])
        sk['lessonFile'] = fname

    def _item(self, fname, sk, sid, item, where):
        item_id = item.get('id', '')
        if not re.fullmatch(r'[a-z0-9][a-z0-9-]{0,19}', item_id):
            self.problem(where, 'id "%s" must be lower case letters, digits and hyphens (at most 20 characters)' % item_id)
            return
        where = '%s (%s)' % (where, item_id)
        aid = '%s.%s.%s' % (self.id, sk['slug'], item_id)
        if aid in self.items:
            self.problem(where, 'the id %s is used twice' % aid)
        kind = item.get('kind')
        if kind == 'raw':
            doc = self._raw_activity(sid, aid, item, where)
        elif kind in RECIPES:
            doc = getattr(self, 'recipe_' + RECIPES[kind])(sk, sid, aid, item, where)
        else:
            self.problem(where, 'unknown kind "%s" (%s or raw)' % (kind, ', '.join(sorted(RECIPES))))
            return
        if doc is None:
            return
        self._add(sk, sid, aid, doc, item_id)
        follow = item.get('then')
        if isinstance(follow, dict) and follow.get('kind') not in RECIPES:
            self.problem(where, 'then: unknown kind "%s"' % follow.get('kind'))
        elif isinstance(follow, dict):
            # A step that goes with the item: the touch on the picture after a say step (`tap`), or the say step after a bubble
            # (`say`). It is an activity of its own, `<id>t` or `<id>s`, played right after.
            step = dict(follow, id=item_id + follow['kind'][0])
            if follow['kind'] == 'say':
                step['afterBubble'] = True  # the say step of a puppet's bubble asks "what do we answer?", not "what is this?"
            step_id = aid + follow['kind'][0]
            step_doc = getattr(self, 'recipe_' + RECIPES[follow['kind']])(sk, sid, step_id, step, where + ' then')
            if step_doc is not None:
                self._add(sk, sid, step_id, step_doc, step['id'])
                self.groups[aid] = [aid, step_id]

    def _add(self, sk, sid, aid, doc, item_id):
        sk['items'].append(aid)
        self.items[aid] = {'doc': doc, 'skill': sid, 'purpose': doc.get('purpose', 'learn'), 'short': '%s.%s' % (sk['slug'], item_id)}
        if doc.get('representation') in REPRESENTATIONS:
            self._skill_reps.setdefault(sid, set()).add(doc['representation'])
        self.put('activity.%s.json' % aid, doc)

    def picture_exists(self, picture):
        return os.path.exists(os.path.join(self.root, 'content', 'languages', 'pictures', picture + '.svg'))

    def _picture(self, picture, where):
        asset = picture.replace('-', '_')
        if not ASSET_ID.fullmatch(asset):
            self.problem(where, 'the picture id "%s" gives no usable asset id' % picture)
            return asset
        have = self.used_pictures.get(asset)
        if have is not None and have != picture:
            self.problem(where, 'the pictures "%s" and "%s" would share the asset id %s' % (have, picture, asset))
        self.used_pictures[asset] = picture
        if not os.path.exists(os.path.join(self.root, 'content', 'languages', 'pictures', picture + '.svg')):
            self.problem(where, 'the picture "%s" is not in content/languages/pictures (the design-director draws it)' % picture)
        return asset

    def _raw_activity(self, sid, aid, item, where):
        """Any other template: the teacher or the app-developer writes the activity's own fields (everything but the id, the course,
        the domain, the band and the review mark, which are set here); the checks of the pack builder apply as to any activity."""
        body = item.get('activity')
        if not isinstance(body, dict) or 'template' not in body:
            self.problem(where, 'a raw item has "activity": the activity document (with its template)')
            return None
        doc = {'schema': 'activity/v1', 'id': aid, 'review': 'needs-editor'}
        doc.update(body)
        doc.update({'id': aid, 'course': self.id, 'domain': DOMAIN})
        doc.setdefault('band', self.skills[sid]['band'])
        doc.setdefault('revision', 1)
        doc['review'] = 'needs-editor'
        doc.setdefault('skills', [{'id': sid, 'weight': 1}])
        if doc.get('representation') not in REPRESENTATIONS:
            self.problem(where, 'a raw activity names its "representation"')
        return doc

    def _raw(self, fname, doc, where):
        """A gate, or any other document kind of the pack: {"kind": "gate", "id": "eng.oral", "doc": {...}}."""
        kind, did, body = doc.get('kind'), doc.get('id'), doc.get('doc')
        if kind not in ('gate',) or not isinstance(did, str) or not isinstance(body, dict):
            self.problem(where, 'a doc is {"kind": "gate", "id": ..., "doc": {...}}')
            return
        if not GATE_ID.fullmatch(did) or not did.startswith(self.id + '.'):
            self.problem(where, 'the gate id "%s" must look like %s.oral (the course, a dot, then 1 to 19 of a-z, 0-9 and _)' % (did, self.id))
            return
        full = {'schema': '%s/v1' % kind, 'id': did, 'review': 'needs-editor', 'course': self.id}
        full.update(body)
        full['id'] = did
        self.put('%s.%s.json' % (kind, did), full)

    # ---- lessons
    def _lesson_ids(self, sid, lesson):
        """The activity ids of a lesson's items, in order (an item that makes two activities, a say step and its tap, gives both)."""
        ids = []
        for ref in lesson.get('items', []):
            qualified = '%s.%s.%s' % (self.id, self.skills[sid]['slug'], ref) if '.' not in ref else '%s.%s' % (self.id, ref)
            if qualified not in self.items:
                self.problem('lesson %s' % lesson.get('id'), 'the item "%s" is not in this course' % ref)
            ids.extend(self.groups.get(qualified, [qualified]))
        return ids

    def _lessons(self):
        number = 0
        seen = set()
        for fname, unit in self.units:
            sid = unit.get('skill', {}).get('id')
            if sid not in self.skills:
                continue
            unit_ids = [self._lesson_ids(sid, lesson) for lesson in unit.get('lessons', [])]
            for i, lesson in enumerate(unit.get('lessons', [])):
                where = '%s lessons[%d]' % (fname, i)
                lid = lesson.get('id', '')
                if not re.fullmatch(r'[a-z0-9][a-z0-9-]{1,30}', lid):
                    self.problem(where, 'id "%s" must be lower case letters, digits and hyphens (2 to 31 characters)' % lid)
                    continue
                full = '%s.%s' % (self.id, lid)
                if full in seen:
                    self.problem(where, 'the lesson id %s is used twice' % full)
                seen.add(full)
                ids = unit_ids[i]
                skills = []
                for aid in ids:
                    s = self.items.get(aid, {}).get('skill')
                    if s and s not in skills:
                        skills.append(s)
                celebration = self.spoken(lesson.get('celebration', self.defaults.get('celebration')), where + ' celebration')
                title = lesson.get('title')
                if not title:
                    self.problem(where, 'needs a title (Hebrew)')
                if not ids or not skills or celebration is None or not title:
                    continue
                number += 1
                self.lessons.append(full)
                extra = {}
                teach = self.lesson_teach(self.skills[sid], i, unit_ids)
                if teach:
                    extra['teach'] = teach
                self.put('lesson.%s.json' % full, dict({
                    'schema': 'lesson/v1',
                    'id': full,
                    'review': 'needs-editor',
                    'revision': lesson.get('revision', 1),
                    'course': self.id,
                    'band': self.skills[sid]['band'],
                    'title': he(title),
                    'skills': skills,
                    'items': ids,
                    'estimatedMinutes': lesson.get('minutes', self.defaults.get('minutes', 4)),
                    'celebration': celebration,
                    'sequence': lesson.get('sequence', number),
                }, **extra))

    # ---- skills, tags, placement, pack
    def _skills(self):
        for sid, sk in sorted(self.skills.items()):
            d = sk['doc']
            where = '%s skill' % sk['file']
            if not d.get('title'):
                self.problem(where, 'needs a title (Hebrew)')
            if not d.get('strand') or not re.match(r'^[a-z]{2,4}$', d.get('strand', '')):
                self.problem(where, 'needs a "strand" (2 to 4 lower case letters, the parent page groups skills by it)')
            if not sk['items']:
                self.problem(where, 'has no items')
            tags = [self.tags[t]['id'] for t in sorted(self._tags_used) if sid in self._tags_used[t] and t in self.tags]
            doc = {
                'schema': 'skill/v1',
                'id': sid,
                'review': 'needs-editor',
                'course': self.id,
                'domain': DOMAIN,
                'band': sk['band'],
                'title': he(d.get('title', '')),
                'strand': d.get('strand', ''),
                'prerequisites': [{'skill': p['skill'], 'weight': p.get('weight', 0.8)} for p in d.get('prerequisites', [])],
                'representations': sorted(self._skill_reps.get(sid, ()), key=REPRESENTATIONS.index),
                'misconceptions': tags,
                'retention': d.get('retention', self.defaults.get('retention', {'targetRetention': 0.9, 'initialStabilityDays': 1})),
            }
            reader = self.reader_as(sk.get('routes'))
            if reader:
                doc['readerAs'] = reader
            for key in SKILL_EXTRAS:
                if key in d:
                    doc[key] = he(d[key]) if key == 'childLine' else d[key]
            for p in d.get('prerequisites', []):
                if p['skill'] not in self.skills:
                    self.problem(where, 'the prerequisite %s is not a skill of this course pack' % p['skill'])
            self.put('skill.%s.json' % sid, doc)

    def _tag_docs(self):
        for key, t in sorted(self.tags.items()):
            where = 'course.json tags.%s' % key
            if not re.fullmatch(r'%s\.[a-z]{2,4}\.[a-z0-9_]{1,24}' % self.id, t.get('id', '')):
                self.problem(where, 'id must be <course>.<strand>.<slug>, for example %s.lis.sem' % self.id)
            if t.get('kind') not in TAG_KINDS:
                self.problem(where, 'kind must be one of %s' % ', '.join(TAG_KINDS))
            if t.get('family') is not None and t['family'] not in FAMILIES:
                self.problem(where, 'family must be one of %s' % ', '.join(FAMILIES))
            if not t.get('parentText'):
                self.problem(where, 'needs "parentText" (Hebrew, for the parent)')
            if key not in self._tags_used:
                continue  # a tag no item of this pack uses is not in the pack
            doc = {'schema': 'misconception/v1', 'id': t['id'], 'review': 'needs-editor', 'course': self.id, 'kind': t['kind']}
            if t.get('family'):
                doc['family'] = t['family']
            doc['skills'] = sorted(self._tags_used[key])
            doc['parentText'] = t.get('parentText', '')
            if t.get('homeActivity'):
                doc['homeActivity'] = he(t['homeActivity'])
            doc['repairActivities'] = [self.id + '.' + r for r in t.get('repair', [])]
            doc['preferredRepresentations'] = t.get('preferredRepresentations', ['pictorial'])
            self.put('misconception.%s.json' % t['id'], doc)

    def _placement(self):
        if self.placement is None:
            return
        p = self.placement
        where = 'placement.json'
        strands = []
        for s in p.get('strands', []):
            levels = []
            for n, level in enumerate(s.get('levels', []), start=1):
                probes = []
                for ref in level.get('items', []):
                    aid = '%s.%s' % (self.id, ref)
                    if aid not in self.items:
                        self.problem(where, 'the probe "%s" is not an item (write it as <skill slug>.<item id>, e.g. a01.p01)' % ref)
                    elif self.items[aid]['purpose'] != 'probe':
                        self.problem(where, 'the probe "%s" must have "purpose": "probe"' % ref)
                    probes.append(aid)
                for a in level.get('assumes', []):
                    if a not in self.skills:
                        self.problem(where, 'strand %s level %d assumes %s, which is not a skill of this pack' % (s.get('id'), n, a))
                entry = {'items': probes}
                if level.get('assumes'):
                    entry['assumes'] = level['assumes']
                levels.append(entry)
            strand = {'id': s.get('id')}
            for key in ('offer', 'start'):
                if key in s:
                    strand[key] = s[key]
            strand['levels'] = levels
            strands.append(strand)
        thanks = self.spoken(p.get('thanks'), where + ' thanks')
        celebration = self.spoken(p.get('celebration'), where + ' celebration')
        if thanks is None or celebration is None:
            return
        self.put('placement.%s.placement.json' % self.id, {
            'schema': 'placement/v1',
            'id': '%s.placement' % self.id,
            'review': 'needs-editor',
            'course': self.id,
            'thanks': thanks,
            'celebration': celebration,
            'perVisit': p.get('perVisit', 8),
            'strands': strands,
        })

    def _pack_json(self):
        pack = self.spec.get('pack', {})
        for asset, picture in sorted(self.used_pictures.items()):
            path = os.path.join(self.root, 'content', 'languages', 'pictures', picture + '.svg')
            if os.path.exists(path):
                with open(path, 'rb') as fh:
                    self.files[asset + '.svg'] = fh.read().replace(b'\r\n', b'\n')
        for asset, (how, picture) in sorted(self.derived.items()):
            base = self.files.get(picture.replace('-', '_') + '.svg') if picture else None
            self.files[asset + '.svg'] = lang_recipes.derived_svg(how, base)
        self.put('pack.json', {
            'schema': 'pack-source/v1',
            'id': 'lang-%s' % self.id,
            'version': pack.get('version', ''),
            'minAppVersion': pack.get('minAppVersion', '0.5.0'),
            'course': self.id,
            'assets': [{'id': a, 'file': a + '.svg'} for a in sorted(set(self.used_pictures) | set(self.derived))],
            'vo': [],
        })
        if not re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}$', pack.get('version', '')):
            self.problem('course.json', 'pack.version must look like 0.1.0')

    def _voice_plan(self):
        """Every clip the pack names and has no recording for, with the text the voice-and-sound-director needs."""
        frame = []
        for line_id in sorted(self.used_lines):
            entry = self.lines.get(line_id, {})
            frame.append({'id': line_id, 'vo': 'vo:%s.%s' % (self.id, line_id.replace('-', '_')), 'he': entry.get('he'),
                          'voice': entry.get('voice'), 'review': entry.get('review', 'needs-editor')})
        target = []
        for clip in sorted(self.used_clips):
            row = self.pronunciation.get(clip, {})
            target.append({'id': clip, 'vo': 'vo:%s.%s' % (self.id, clip.replace('-', '_')), 'shown': row.get('shown'),
                           'say': row.get('say'), 'ipa': row.get('ipa')})
        self.voice_plan = {'course': self.id, 'pack': 'lang-%s' % self.id, 'frameLines': frame, 'targetClips': target}
        if self.cut_clips:
            # The clips of single words, cut from the clip of the page by word timing: nothing of them is voiced, so nothing is paid.
            self.voice_plan['cutClips'] = [dict(c, vo='vo:%s.%s' % (self.id, c['id'].replace('-', '_'))) for _, c in sorted(self.cut_clips.items())]

    def plan_bytes(self):
        return (json.dumps(self.voice_plan, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


# ------------------------------------------------------------------ writing


def outputs(course, root=ROOT):
    """(pack folder, {relative path: bytes}) of a course; raises SpecError."""
    c = Course(course, root)
    files = c.build()
    odd = sorted(name for name in files if not FILE_NAME.fullmatch(name))
    if odd:
        raise SpecError(['%s: the file name %r is not a plain name (a pack file has no folder in its name)' % (course, n) for n in odd])
    base = os.path.join(root, 'content', 'languages', course)
    out = {os.path.join(base, 'pack', name): data for name, data in files.items()}
    out[os.path.join(base, 'voice-plan.json')] = c.plan_bytes()
    return os.path.join(base, 'pack'), out


def refuse_outside(course, pack_dir, out, root):
    """Raises SpecError unless every file of the pack lands directly in <course>/pack once links are resolved (the voice plan, next to the
    pack, is the one other file). Called before any folder is made or any file is written."""
    pack_real = os.path.normcase(os.path.realpath(pack_dir))
    plan = os.path.join(root, 'content', 'languages', course, 'voice-plan.json')
    bad = [p for p in out if p != plan and os.path.normcase(os.path.dirname(os.path.realpath(p))) != pack_real]
    if bad:
        raise SpecError(['%s: %s would be written outside content/languages/%s/pack' % (course, os.path.relpath(p, root), course)
                         for p in sorted(bad)])


def run(courses=COURSES, root=ROOT, check=False, quiet=False):
    """Writes (or with check=True only compares) the generated files of each course that has a course.json. Returns the files that
    are out of date (always empty after a write)."""
    stale = []
    for course in courses:
        if not os.path.exists(os.path.join(root, 'content', 'languages', course, 'course.json')):
            continue
        pack_dir, out = outputs(course, root)
        refuse_outside(course, pack_dir, out, root)
        existing = set(glob.glob(os.path.join(pack_dir, '*'))) if os.path.isdir(pack_dir) else set()
        for path in sorted(existing - set(out)):
            if check:
                stale.append(path)
            else:
                os.remove(path)
        for path, data in sorted(out.items()):
            current = None
            if os.path.exists(path):
                with open(path, 'rb') as fh:
                    current = fh.read()
            if current == data:
                continue
            if check:
                stale.append(path)
                continue
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, 'wb') as fh:
                fh.write(data)
        if not quiet:
            print('%s: %d files in %s' % (course, len(out) - 1, os.path.relpath(pack_dir, root)))
    return stale


def main(argv, root=ROOT):
    # A problem may quote Hebrew; a Windows console that is not UTF-8 must not stop the report.
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = [a for a in argv if not a.startswith('--')]
    if not args:
        print(__doc__)
        return 2
    courses = COURSES if args[0] == 'all' else tuple(args)
    for c in courses:
        if c not in COURSES:
            print('unknown course "%s" (eng, heb, rus or all)' % c)
            return 2
    try:
        stale = run(courses, root=root, check='--check' in argv)
    except SpecError as e:
        print('The course files have %d problem(s):' % len(e.problems))
        for p in e.problems:
            print('  ' + p)
        return 1
    if stale:
        print('Out of date (run `python tools/lang_pack.py all`):')
        for p in stale:
            print('  ' + os.path.relpath(p, root))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
