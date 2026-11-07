"""Teach screens and routes of a course, for tools/lang_pack.py (class `Routes`, which `Course` takes).

A Russian child plays a course by a route: `new` (a new learner), `heritage` (hears Russian at home) or `reader` (reads Russian). The
teachers' unit files say what each route is served (docs/languages/russian/band-a-content.md section 2, "Routes"):

    "teach":  [["w-mama", "w-papa"], ["w-brat", ...]]    the new words of the skill, in sets of 4 to 5 (clip ids of the clip table)
    "routes": {"new": {...}, "heritage": {"teach": false, "from": "05"}, "reader": {"as": "new"}}

and course.json says the picture of each teach word (`teachPictures`: clip -> picture id) and the lines of a teach screen (`defaults.teach`:
`frame`, `heard`, `together`). The generator makes

* a **teach screen** for each word: a `say_it` activity (LS09, echo: the picture, the word, a pause, the word again; the child says it
  or touches "I said it", with no microphone) flagged `answer.teach`, which the app plays unscored and keeps out of the engine's catalogue;
* in the lessons: `teach` (the sets, each with the routes that see them, put before the first lesson whose items use a word of the set).

A route record that says `"as": "<route>"` is served as that route. `teach` is true unless the record says false. A route a record does not
name is served as `new`. The other keys of a record (`from`, `order`, `weight`, `say`, `embodied`, `note`) are the teacher's and are not
read yet: a heritage child who starts later on the path, or in another order, needs a path that knows the route (docs/languages/
band-a-build.md section 2.4). Standard library only.
"""
import re

ROUTES = ('new', 'heritage', 'reader')
# A teach screen's item ids: `tc01`, `tc02` ... in the order of the unit's sets (the item id is at most 20 characters).
TEACH_ID = 'tc%02d'


class Routes:
    """The teach screens and the routes. `self` is a Course (tools/lang_pack.py)."""

    # ------------------------------------------------------------ what a route is served
    def route_record(self, routes, route):
        """(the route that serves [route], its record): the record `as` points to, and `new` for a route the unit does not name."""
        seen = []
        while route not in seen:
            seen.append(route)
            record = (routes or {}).get(route)
            if record is None:
                return ('new', {}) if route == 'new' else self.route_record(routes, 'new')
            if isinstance(record, dict) and isinstance(record.get('as'), str):
                route = record['as']
                continue
            return route, (record if isinstance(record, dict) else {})
        return 'new', {}

    def teach_routes(self, routes):
        """The routes that see the teach screens: those served as the new learner or the reader whose record does not say `"teach": false`.
        A heritage speaker is never one of them, whatever a record says (the syllabus's rule), and a reader who is served as a heritage
        speaker (`"as": "heritage"`) is not either."""
        out = []
        for r in ('new', 'reader'):
            served, record = self.route_record(routes, r)
            if served != 'heritage' and record.get('teach', True) is not False:
                out.append(r)
        return out

    def check_routes(self, fname, unit):
        routes = unit.get('routes')
        if routes is None:
            return
        where = fname + ' routes'
        if not isinstance(routes, dict):
            self.problem(where, 'is an object: {"new": {...}, "heritage": {...}, "reader": {...}}')
            return
        for route, record in routes.items():
            if route not in ROUTES:
                self.problem(where, 'the route "%s" is not new, heritage or reader' % route)
            elif not isinstance(record, dict):
                self.problem(where, 'the record of "%s" is an object (use "note" for the teacher\'s words)' % route)
            elif 'as' in record and record['as'] not in ROUTES:
                self.problem(where, '"as" of "%s" names a route (new, heritage or reader)' % route)
        for route in ROUTES:  # a cycle of `as` would never end
            seen, cur = [], route
            while isinstance(routes.get(cur), dict) and 'as' in routes[cur]:
                if cur in seen:
                    self.problem(where, 'the routes "%s" point at each other with "as"' % route)
                    break
                seen.append(cur)
                cur = routes[cur]['as']

    # ------------------------------------------------------------ teach screens
    def teach_items(self, fname, sk, sid, unit):
        """Makes the teach screen of every word of the unit's `teach` sets; sk['teach'] is the list of sets (each a list of activity ids)."""
        sets = unit.get('teach')
        sk['teach'] = []
        if sets is None:
            return
        where = fname + ' teach'
        if not (isinstance(sets, list) and all(isinstance(s, list) and s for s in sets)):
            self.problem(where, 'is a list of sets, each a list of clip ids: [["w-mama", "w-papa"], ...]')
            return
        settings = self.defaults.get('teach') or {}
        pictures = self.spec.get('teachPictures') or {}
        number = 0
        for si, clips in enumerate(sets):
            ids = []
            for clip in clips:
                number += 1
                item_id = TEACH_ID % number
                aid = '%s.%s.%s' % (self.id, sk['slug'], item_id)
                here = '%s (%s, %s)' % (where, item_id, clip)
                row = self.clip_row(clip, here)
                picture = pictures.get(clip)
                if row is None:
                    continue
                if not picture:
                    self.problem(here, 'the word has no picture in course.json "teachPictures"')
                    continue
                if aid in self.items:
                    self.problem(here, 'the id %s is used twice' % aid)
                    continue
                others = [c for j, c in enumerate(clips) if j != clips.index(clip)]
                item = {'id': item_id, 'kind': 'say', 'purpose': 'practice', 'picture': picture, 'clip': clip, 'rep': 'embodied',
                        'forms': [plain_word(row.get('shown'))], 'foils': self._foils(clip, others, here),
                        'frame': settings.get('frame'), 'heard': settings.get('heard'), 'together': settings.get('together')}
                if ' ' in item['forms'][0]:
                    item['keyWords'] = item['forms'][0].split(' ')
                doc = self.recipe_say(sk, sid, aid, {k: v for k, v in item.items() if v is not None}, here)
                if doc is None:
                    continue
                doc['answer']['teach'] = True
                # A teach screen is not evidence of anything (the child is shown the word, not asked it): its representation is not counted
                # for the skill, and the engine never sees it.
                self.items[aid] = {'doc': doc, 'skill': sid, 'purpose': 'practice', 'short': '%s.%s' % (sk['slug'], item_id),
                                   'teach': True}
                self.put('activity.%s.json' % aid, doc)
                self.teach_count += 1
                ids.append(aid)
            sk['teach'].append(ids)

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
        """The `teach` entries of lesson number [lesson_index] of the unit. A set is put before the first lesson that asks one of its words
        (the clip its prompt plays); a set no lesson asks by word (the body parts are asked by a phrase) goes to the lesson of its own
        number, or the last. [lessons_ids] are the activity ids of every lesson of the unit, in order."""
        routes = self.teach_routes(sk.get('routes'))
        entries = []
        for number, ids in enumerate(sk.get('teach', [])):
            if ids and self._lesson_for(ids, number, lessons_ids) == lesson_index:
                entries.append({'items': ids, 'routes': routes})
        return [e for e in entries if e['routes']]

    def _lesson_for(self, teach_ids, number, lessons_ids):
        words = {self.items[a]['doc']['say']['clip'] for a in teach_ids}
        for n, ids in enumerate(lessons_ids):
            asked = {self.items[a]['doc'].get('prompt', {}).get('target') for a in ids if a in self.items}
            if words & asked:
                return n
        return min(number, len(lessons_ids) - 1)


def plain_word(shown):
    """A clip's shown text as the recogniser's list holds it: lower case, no punctuation, no stress mark."""
    text = re.sub('[\u0301.,!?;:"\u00ab\u00bb\u2026]', '', (shown or '')).strip().lower()
    return re.sub(r'\s+', ' ', text)
