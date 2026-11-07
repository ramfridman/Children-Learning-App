"""Teach screens, hearing screens and routes of a course, for tools/lang_pack.py (class `Routes`, which `Course` takes).

A Russian child plays a course by a route: `new` (a new learner), `heritage` (hears Russian at home) or `reader` (reads Russian). The
reader has no screens of its own: the app serves it, skill by skill, as `new` or as `heritage` (docs/languages/band-a-build.md section
2.6.1 R1). The teachers' unit files say what each route is served (docs/languages/russian/band-a-content.md section 2, "Routes"):

    "teach":  [["w-mama", "w-papa"], ["w-brat", ...]]    the new words of the skill, in sets of 4 to 6 (clip ids of the clip table)
    "routes": {"new": {...}, "heritage": {"hear": true, "say": "picture"}, "reader": {"as": "oral"}}

and course.json says the picture of each teach word (`teachPictures`: clip -> picture id), the lines of a teach screen (`defaults.teach`:
`frame`, `heard`, `together`), of a hearing screen (`defaults.hear`: `frame`) and the order of the say steps (`defaults.sayOrder`). The
generator makes

* a **teach screen** for each word (`tcNN`): a `say_it` activity (LS09, echo: the picture, the word, a pause, the word again; the child
  says it or touches "I said it", with no microphone) flagged `answer.teach`, which the app plays unscored and keeps out of the engine's
  catalogue;
* a **hearing screen** (`thNN`, the number of the teach screen of the same word) for a unit whose heritage record says `"hear": true`: the
  same activity with `answer.hear` too: the line and the word once, no microphone, no "I said it", a free replay, the picture after the
  word. Like a teach screen it is no item of any lesson and the engine does not see it;
* in the lessons: `teach`, the entries `{"items", "routes", "mode"}`: a `teach` entry (routes: `new` only) per set of teach screens, put
  before the first lesson whose items use a word of the set, and a `hear` entry (routes: `heritage` only) per lesson, holding the hearing
  screens of the words that lesson asks first;
* on each skill the reader's route (`readerAs`: `oral`, the default, or `heritage`) from the record `"reader": {"as": ...}`; and on each
  say step that is not one of these screens the order it is played in per served route (`say.order`) and the line that asks the child to
  say the word before it is heard (`say.pictureFirst`).

A route record may also say `"teach": false` (the new learner is not shown teach screens in the unit). The other keys (`from`, `order`,
`weight`, `embodied`, `note`) are the teacher's notes and are not read: a route only adds screens before a lesson and sets the order of a
say step, it never removes, adds or reorders a lesson's items (R5). Standard library only.
"""
import re

ROUTES = ('new', 'heritage', 'reader')
READER_AS = ('oral', 'heritage')
SAY_ORDERS = ('echo', 'picture')
# A teach screen's item ids: `tc01`, `tc02` ... in the order of the unit's sets; a hearing screen's: `th01` ... with the number of the same
# word (the item id is at most 20 characters).
TEACH_ID = 'tc%02d'
HEAR_ID = 'th%02d'


class Routes:
    """The teach screens, the hearing screens and the routes. `self` is a Course (tools/lang_pack.py)."""

    # ------------------------------------------------------------ what a route is served
    def check_routes(self, fname, unit):
        routes = unit.get('routes')
        if routes is None:
            return
        where = fname + ' routes'
        if not isinstance(routes, dict):
            self.problem(where, 'is an object: {"new": {...}, "heritage": {...}, "reader": {"as": "oral"}}')
            return
        for route, record in routes.items():
            if route not in ROUTES:
                self.problem(where, 'the route "%s" is not new, heritage or reader' % route)
            elif not isinstance(record, dict):
                self.problem(where, 'the record of "%s" is an object (use "note" for the teacher\'s words)' % route)
            else:
                self._check_record(where, route, record, unit)

    def _check_record(self, where, route, record, unit):
        if 'as' in record:
            if route != 'reader':
                self.problem(where, 'only the reader\'s record says "as" (the other routes are what they are)')
            elif record['as'] == 'new':
                self.problem(where, 'the reader is not served as "new": write "oral" (strand 1 of the placement decides) or "heritage"')
            elif record['as'] not in READER_AS:
                self.problem(where, '"as" of the reader is "oral" or "heritage"')
        if 'say' in record:
            if route == 'reader':
                self.problem(where, 'the reader has no "say": it is served as new or heritage')
            elif record['say'] not in SAY_ORDERS:
                self.problem(where, '"say" of "%s" is "echo" or "picture" (not "%s")' % (route, record['say']))
        if 'hear' in record:
            if route != 'heritage':
                self.problem(where, '"hear" (the hearing screens) is for the heritage route only')
            elif record['hear'] is not True and record['hear'] is not False:
                self.problem(where, '"hear" is true or false')
            elif record['hear'] and not unit.get('teach'):
                self.problem(where, '"hear" needs the unit\'s "teach" (the words to be heard)')

    def teach_routes(self, routes):
        """The routes the teach screens are shown to: `new`, unless its record says `"teach": false`. The reader is served as new or as
        heritage before the lesson is built, and a heritage speaker is never shown a teach screen (the syllabus's rule)."""
        record = (routes or {}).get('new')
        return [] if isinstance(record, dict) and record.get('teach') is False else ['new']

    def hears(self, routes):
        """Does the unit give the heritage route its single hearing of the new words?"""
        record = (routes or {}).get('heritage')
        return isinstance(record, dict) and record.get('hear') is True

    def reader_as(self, routes):
        """`oral` or `heritage`: how the reader is served in the skill (None when the unit has no record of it)."""
        record = (routes or {}).get('reader')
        return record.get('as') if isinstance(record, dict) and record.get('as') in READER_AS else None

    # ------------------------------------------------------------ the say step's order
    def say_order(self, sk):
        """The order the say steps of a skill are played in, per served route: the course's `defaults.sayOrder`, changed by the unit's
        `routes.<route>.say`. None when the course sets none (only the Russian course has routes)."""
        base = self.defaults.get('sayOrder')
        if not base:
            return None
        order = {route: base.get(route, 'echo') for route in ('new', 'heritage')}
        for route in order:
            record = (sk.get('routes') or {}).get(route)
            if isinstance(record, dict) and record.get('say') in SAY_ORDERS:
                order[route] = record['say']
        return order

    def picture_first(self, item, where):
        """The line that asks the child to say the word before it is heard (`say.pictureFirst`), with no clip after it: the item's own
        `pictureFirst`, else `defaults.afterBubble` for a say step that follows a puppet's bubble, else the item's `frame`, else
        `defaults.pictureFirst`."""
        line = item.get('pictureFirst')
        if not line and item.get('afterBubble'):
            line = self.defaults.get('afterBubble')
        line = line or item.get('frame') or self.defaults.get('pictureFirst')
        spoken = self.spoken({'line': line}, where + ' pictureFirst', item)
        return spoken

    # ------------------------------------------------------------ teach screens and hearing screens
    def teach_items(self, fname, sk, sid, unit):
        """Makes the teach screen of every word of the unit's `teach` sets, and its hearing screen when the heritage record asks for one.
        sk['teach'] is the list of sets (each a list of activity ids); sk['hear'] the hearing screens as (activity id, number of the set
        the word is in), in the order of the words."""
        sets = unit.get('teach')
        sk['teach'] = []
        sk['hear'] = []
        if sets is None:
            return
        where = fname + ' teach'
        if not (isinstance(sets, list) and all(isinstance(s, list) and s for s in sets)):
            self.problem(where, 'is a list of sets, each a list of clip ids: [["w-mama", "w-papa"], ...]')
            return
        hear = self.hears(sk.get('routes'))
        number = 0
        for set_number, clips in enumerate(sets):
            ids = []
            for clip in clips:
                number += 1
                here = '%s (%s, %s)' % (where, TEACH_ID % number, clip)
                others = [c for j, c in enumerate(clips) if j != clips.index(clip)]
                aid = self._screen(sk, sid, 'teach', TEACH_ID % number, clip, others, here)
                if aid is None:
                    continue
                ids.append(aid)
                if hear:
                    heard = self._screen(sk, sid, 'hear', HEAR_ID % number, clip, others, '%s (%s, %s)' % (where, HEAR_ID % number, clip))
                    if heard is not None:
                        sk['hear'].append((heard, set_number))
            sk['teach'].append(ids)

    def _screen(self, sk, sid, kind, item_id, clip, others, where):
        """One teach screen or hearing screen: the activity id, or None (the problem is said)."""
        aid = '%s.%s.%s' % (self.id, sk['slug'], item_id)
        settings = dict(self.defaults.get('teach') or {})
        if kind == 'hear':
            settings.update(self.defaults.get('hear') or {})
        row = self.clip_row(clip, where)
        picture = (self.spec.get('teachPictures') or {}).get(clip)
        if row is None:
            return None
        if not picture:
            self.problem(where, 'the word has no picture in course.json "teachPictures"')
            return None
        if aid in self.items:
            self.problem(where, 'the id %s is used twice' % aid)
            return None
        item = {'id': item_id, 'kind': 'say', 'purpose': 'practice', 'picture': picture, 'clip': clip, 'rep': 'embodied',
                'forms': [plain_word(row.get('shown'))], 'foils': self._foils(clip, others, where),
                'frame': settings.get('frame'), 'heard': settings.get('heard'), 'together': settings.get('together'), '_screen': kind}
        if ' ' in item['forms'][0]:
            item['keyWords'] = item['forms'][0].split(' ')
        doc = self.recipe_say(sk, sid, aid, {k: v for k, v in item.items() if v is not None}, where)
        if doc is None:
            return None
        doc['answer']['teach'] = True
        if kind == 'hear':
            doc['answer']['hear'] = True
        # A screen is not evidence of anything (the child is shown the word, not asked it): its representation is not counted for the
        # skill, and the engine never sees it.
        self.items[aid] = {'doc': doc, 'skill': sid, 'purpose': 'practice', 'short': '%s.%s' % (sk['slug'], item_id), 'teach': True}
        self.put('activity.%s.json' % aid, doc)
        self.teach_count += 1
        return aid

    def _foils(self, clip, others, where):
        """The words the recogniser must not take for this one: the other words of its set (at most two), in their plain spelling."""
        foils = []
        for other in others:
            row = self.pronunciation.get(other)
            word = plain_word(row.get('shown')) if row else ''
            if word and word != plain_word(self.pronunciation[clip].get('shown')) and word not in foils:
                foils.append(word)
        if not foils:
            self.problem(where, 'a teach set of one word has no foil: add a word to the set')
        return foils[:2]

    # ------------------------------------------------------------ in the lessons
    def lesson_teach(self, sk, lesson_index, lessons_ids):
        """The `teach` entries of lesson number [lesson_index] of the unit. A set of teach screens is put before the first lesson that asks
        one of its words (the clip its prompt plays); a set no lesson asks by word (the body parts are asked by a phrase) goes to the lesson
        of its own number, or the last. Each hearing screen is put before the first lesson that asks its word, so the words of a minimal
        pair are heard just before they are asked. [lessons_ids] are the activity ids of every lesson of the unit, in order."""
        entries = []
        routes = self.teach_routes(sk.get('routes'))
        for number, ids in enumerate(sk.get('teach', [])):
            if routes and ids and self._lesson_for(ids, number, lessons_ids) == lesson_index:
                entries.append({'items': ids, 'routes': routes, 'mode': 'teach'})
        heard = [aid for aid, number in sk.get('hear', []) if self._lesson_for([aid], number, lessons_ids) == lesson_index]
        if heard:
            entries.append({'items': heard, 'routes': ['heritage'], 'mode': 'hear'})
        return entries

    def _lesson_for(self, teach_ids, number, lessons_ids):
        words = {self.items[a]['doc']['say']['clip'] for a in teach_ids}
        for n, ids in enumerate(lessons_ids):
            asked = {self.items[a]['doc'].get('prompt', {}).get('target') for a in ids if a in self.items}
            if words & asked:
                return n
        return min(number, len(lessons_ids) - 1)


def plain_word(shown):
    """A clip's shown text as the recogniser's list holds it: lower case, no punctuation, no stress mark."""
    text = re.sub('[́.,!?;:"«»…]', '', (shown or '')).strip().lower()
    return re.sub(r'\s+', ' ', text)
