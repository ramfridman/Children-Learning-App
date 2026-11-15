"""The lesson shape of docs/milestones/L7.md section 3 in a course's authoring files, for tools/lang_pack.py (class `Meet`, which `Course` takes).

A lesson of a new learner has four parts: Recall, Meet, Find and Use. A teacher may write a lesson in that shape,

    {"id": "greet-1", "title": "...",
     "recall": ["i20"],                                   scored items on words met in earlier lessons (1 to 2)
     "meet":   [["en-hello", "en-goodbye"]],              the new words, one Meet screen each (a set is 2 to 3 words)
     "find":   ["i01", "i02", "i05"],                     scored picture choices on the new words (2 or more items per word)
     "use":    ["i07", "r01"]}                            the words in use: say it, listen and do, a puppet turn, a chant

and the generator flattens it: the lesson's items are `recall`, `find` and `use` in that order, and each Meet set stands before the first
`find` item (or, with `"before": "<item>"`, before that item, so that a set may stand anywhere):

    "meet": [{"words": ["en-hello", "en-goodbye"], "before": "i05"}]

A word is its clip id, or `{"clip": "w-x", "picture": "story-pic", "explain": "line-id", "focus": [x, y, w, h]}`: the picture overrides
`teachPictures` of course.json, `explain` is the Hebrew sentence that explains the word (the Hebrew course), `focus` the part of the picture
the word names (shares of the picture). A lesson with `items` is the old form and keeps working until its teacher re-cuts the unit.

course.json says the lines of a Meet screen in `defaults.teach`: `frame` and `together` (let's say it together), `heard`, and optionally
`opener` (said before the first word of a set), `hear` (a carrier said before the word), `meaning` (the carrier of the Hebrew meaning,
"in Hebrew:"; the course's `glosses` say each word's meaning) or `explain: true` (each word names an `explain` line); and `defaults.where`,
the line "and where is ...?" said after the tapped word on the first wrong tap of a picture choice. Standard library only.
"""
import lang_routes

PARTS = ('recall', 'meet', 'find', 'use')


class Meet:
    """The parts of a lesson and its Meet screens. `self` is a Course (tools/lang_pack.py)."""

    # ------------------------------------------------------------ the shape of a lesson
    @staticmethod
    def new_shape(lesson):
        """Is the lesson written in the four parts (and not with `items`)?"""
        return any(part in lesson for part in PARTS)

    def lesson_refs(self, lesson, where=None):
        """The item references of a lesson in play order: `items`, or `recall`, `find` and `use` (the Meet screens are not items). With a
        [where] the problems are said."""
        if not self.new_shape(lesson):
            return list(lesson.get('items', []))
        if 'items' in lesson and where:
            self.problem(where, 'a lesson is written with "items" or with "recall", "meet", "find" and "use", not both')
        refs = []
        for part in ('recall', 'find', 'use'):
            value = lesson.get(part, [])
            if not isinstance(value, list) or not all(isinstance(r, str) for r in value):
                if where:
                    self.problem(where, '"%s" is a list of item ids' % part)
                continue
            refs += value
        return refs

    def part_of(self, lesson, ref):
        """`recall`, `find` or `use`: the part of the lesson that holds [ref] (None for a lesson in the old form)."""
        for part in ('recall', 'find', 'use'):
            if ref in (lesson.get(part) or []):
                return part
        return None

    # ------------------------------------------------------------ the Meet sets of a lesson
    def meet_sets(self, lesson, where):
        """The lesson's Meet sets as [{"words": [word dict], "before": item ref or None}], the problems said."""
        raw = lesson.get('meet')
        if raw is None:
            return []
        if not isinstance(raw, list) or not raw:
            self.problem(where, '"meet" is a list of sets: [["w-a", "w-b"]] or [{"words": [...], "before": "<item>"}]')
            return []
        sets = []
        refs = self.lesson_refs(lesson)
        for n, entry in enumerate(raw):
            here = '%s meet[%d]' % (where, n)
            before = None
            words = entry
            if isinstance(entry, dict):
                words = entry.get('words')
                before = entry.get('before')
            if not isinstance(words, list) or not words:
                self.problem(here, 'a set is a list of words (clip ids)')
                continue
            if before is not None and before not in refs:
                self.problem(here, '"before" names "%s", which is not an item of the lesson' % before)
                before = None
            if before is None and refs:
                before = next((r for r in lesson.get('find', []) if r in refs), refs[0])
            sets.append({'words': [self._word(w, here) for w in words], 'before': before})
        return sets

    def _word(self, word, where):
        face = {'clip': word} if isinstance(word, str) else dict(word) if isinstance(word, dict) else {}
        if not isinstance(face.get('clip'), str):
            self.problem(where, 'a word is a clip id, or {"clip": ..., "picture": ..., "explain": ..., "focus": [x, y, w, h]}')
            face['clip'] = ''
        return face

    def meet_screens(self, fname, sk, sid, unit):
        """Makes the Meet screen of every word of the lessons' Meet sets (ids `tcNN`, after those of the unit's own `teach`).
        sk['meet'] maps the lesson's index to its sets: [{"ids": [activity ids], "before": item ref or None}]."""
        sk['meet'] = {}
        number = sk.get('screen_count', 0)
        for i, lesson in enumerate(unit.get('lessons', [])):
            where = '%s lessons[%d]' % (fname, i)
            made = []
            for entry in self.meet_sets(lesson, where):
                words = entry['words']
                ids = []
                for pos, word in enumerate(words):
                    number += 1
                    clip = word['clip']
                    here = '%s meet (%s, %s)' % (where, lang_routes.TEACH_ID % number, clip)
                    others = [w['clip'] for j, w in enumerate(words) if j != pos]
                    meet = self._meet_data(word, words[:pos], pos, len(words), here)
                    aid = self._screen(sk, sid, 'teach', lang_routes.TEACH_ID % number, clip, others, here, picture=word.get('picture'),
                                       meet=meet)
                    if aid is not None:
                        ids.append(aid)
                if ids:
                    made.append({'ids': ids, 'before': entry['before']})
            if made:
                sk['meet'][i] = made
        sk['screen_count'] = number

    def _meet_data(self, word, earlier, position, size, where):
        """What a Meet screen needs beyond a teach screen: its place in its set, the words met before it in the set (for the strip), the
        opener (first word of a set only), the carrier before the word, and the Hebrew meaning or explanation (docs/design/l7-meet-find.md
        section 10.1). {} when the course sets none of it."""
        teach = self.defaults.get('teach') or {}
        meet = {'position': position, 'size': size}
        if earlier:
            meet['earlier'] = [self._earlier(w, where) for w in earlier]
        if position == 0 and teach.get('opener'):
            opener = self.spoken({'line': teach['opener']}, where + ' opener')
            if opener:
                meet['opener'] = opener
        clip = word['clip']
        if teach.get('hear'):
            hear = self.spoken({'line': teach['hear'], 'target': clip}, where + ' hear')
            if hear:
                meet['hear'] = hear
        if teach.get('meaning'):
            line = self.glosses.get(clip)
            if not line:
                self.problem(where, 'the word has no gloss in course.json "glosses" (the Meet screen says its Hebrew meaning once)')
            else:
                meaning = self._meaning(teach['meaning'], line, where)
                if meaning:
                    meet['meaning'] = meaning
        if teach.get('explain'):
            line = word.get('explain')
            if not line:
                self.problem(where, 'the word needs "explain": the line that explains it in one short Hebrew sentence')
            else:
                explain = self.spoken({'line': line}, where + ' explain')
                if explain:
                    meet['explain'] = explain
        if word.get('focus') is not None:
            focus = word['focus']
            ok = isinstance(focus, list) and len(focus) == 4 and all(isinstance(v, (int, float)) and 0 <= v <= 1 for v in focus)
            if ok and focus[0] + focus[2] <= 1.0001 and focus[1] + focus[3] <= 1.0001:
                meet['focus'] = [round(float(v), 4) for v in focus]
            else:
                self.problem(where, '"focus" is [x, y, w, h], shares of the picture that stay inside it')
        row = self.pronunciation.get(clip)
        if row and row.get('shown'):
            # What the chip under the bubble prints when the child's letters are open (a Band A skill carries it as data only: the app
            # shows it by its own rule, docs/design/l7-meet-find.md section 3.2). Not a `show`: nothing is printed by the screen itself.
            written = row['shown'].rstrip(' .!?,')
            meet['written'] = written.lower() if self.id == 'eng' else written  # English is lower case until C-13 (frame section 2.3)
        return meet

    def _earlier(self, word, where):
        picture = word.get('picture') or (self.spec.get('teachPictures') or {}).get(word['clip'])
        entry = {'sprite': self.asset(picture, where) if picture else None, 'clip': self.clip(word['clip'], where)}
        if entry['sprite'] is None:
            self.problem(where, 'the word "%s" has no picture in course.json "teachPictures"' % word['clip'])
        return entry

    def _meaning(self, carrier, gloss_line, where):
        """The Hebrew meaning as one Spoken: the carrier ("in Hebrew:"), then the gloss line as the clip that follows it; the caption holds both."""
        carrier_text = self.line_text(carrier, where + ' meaning')
        gloss_text = self.line_text(gloss_line, where + ' gloss')
        if carrier_text is None or gloss_text is None:
            return None
        self.used_lines.update((carrier, gloss_line))
        return {'vo': self.vo(carrier), 'caption': [{'t': 'he', 'v': '%s %s' % (carrier_text, gloss_text)}], 'target': self.vo(gloss_line)}

    # ------------------------------------------------------------ in the lesson document
    def meet_entries(self, sk, lesson_index, ids):
        """The `teach` entries of a lesson written in the four parts: {"items", "routes", "mode", "before"} for each Meet set, `before`
        being the activity id of the item the set stands in front of (left out for a set at the very start). [ids] are the lesson's
        activity ids in order, by lesson, for the unit."""
        routes = self.teach_routes(sk.get('routes'))
        entries = []
        for made in sk.get('meet', {}).get(lesson_index, []):
            if not routes:
                continue
            entry = {'items': made['ids'], 'routes': routes, 'mode': 'teach'}
            first = self.first_activity(sk, made['before'], ids[lesson_index])
            if first and first != ids[lesson_index][0]:
                entry['before'] = first
            entries.append(entry)
        return entries

    def first_activity(self, sk, ref, lesson_ids):
        """The activity id of item [ref] (its first activity, for an item that makes two), or None."""
        if ref is None:
            return None
        qualified = '%s.%s.%s' % (self.id, sk['slug'], ref) if '.' not in ref else '%s.%s' % (self.id, ref)
        found = self.groups.get(qualified, [qualified])[0]
        return found if found in lesson_ids else None

