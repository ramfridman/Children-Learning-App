"""The rule "met before asked" of docs/languages/frame.md section 3.5.1 (step L7-5 of docs/milestones/L7.md), for tools/lang_pack.py.

The check walks a course's lessons in `sequence` order as a new learner who knows nothing, and says what the course asks of a word before
it has taught it. It reads the pack the generator has just written (the lesson documents and their activities), so it sees exactly what the
app will play: a lesson's Meet screens stand where its `teach` sets say (`before`), and a word is *met* from the Meet screen on.

Refused (rule, what it says):

    not-met      a scored item whose target or one of its options is a word that no Meet screen has taught yet (Hebrew: unless the word is
                 in course.json `everyday`)
    unnamed      a picture option of a scored item that names no word clip, so the app cannot say it when it is touched
    meet-size    a Meet set of more than 3 words
    first-find   the first scored item on a new word has more than 2 choices
    find-count   a new word is the target of fewer than 2 Find items in its lesson
    no-use       a lesson with no Use item (say it, listen and do, a puppet turn or a chant)
Warned (never fails a build):

    recall       a new word is not the target of a scored item in any of the next 3 lessons

What is a word to meet. The words of an item are the clip it asks (`asks`, a command such as "touch your nose"), the clip its prompt ends
with (the stem), the clip a say step says, and the clip of each option. Four kinds of clip are not words and need no Meet screen (and, in the
Hebrew course, no `everyday` mark), and they are found from the pack, not listed by a teacher:

    page         a narration clip of a story page, and the clip of an option whose picture is a story page ("which came first?")
    count        the clip of an option whose picture is a beat strip (`drum_strip_*`: "one drum", "two drums"); such a picture names no word
    sentence     the clip of an option whose picture is a place scene (`place_*`: "the ball is on the box")
    carrier      a prompt that no option, no say step, no `asks` and no Meet screen of the course ever names as a word: a syllable string
                 ("bu-ba"), a verse with a gap, a question that is never taught as a chunk. A question chunk the course does teach by a Meet
                 screen ("what's this?") is a word and is held to the rule

Two modes, set for the whole course by course.json `"metBefore"`:

    "report"     (the default) a lesson written in the old form (`items`) is only reported: its violations are listed, and the build does
                 not fail on them. A lesson written in the four parts (`recall`, `meet`, `find`, `use`, tools/lang_meet.py) is enforced.
    "enforce"    every lesson is enforced. A teacher switches a course to it when the unit files are re-cut (step L7-6): the one line
                 `"metBefore": "enforce"` in course.json.

`python tools/lang_pack.py <course> --met-before` prints every finding of the course, grouped by rule and lesson, and never fails.
Standard library only.
"""
import re
from collections import Counter, namedtuple

RULES = ('not-met', 'unnamed', 'meet-size', 'first-find', 'find-count', 'no-use', 'recall')
MODES = ('report', 'enforce')
# What a Use item may be (frame section 3.5.1): say it (LS09), listen and do (LS11), a puppet turn (LS10), a chant (LS12).
USE_TEMPLATES = ('say_it', 'listen_do', 'puppet_talk', 'sing_along')
RECALL_WINDOW = 3
MEET_MAX = 3
FIRST_FIND_MAX = 2
FIND_MIN = 2

Finding = namedtuple('Finding', 'rule lesson where message enforced')


def word_of(vo):
    """The word a clip says: its id without the slow version's suffix."""
    return re.sub(r'_slow$', '', vo) if isinstance(vo, str) else vo


def text_face(doc):
    """Does the item print its options (letters, a text stem)? Those are not words to meet."""
    answer = doc.get('answer') or {}
    return bool(answer.get('face')) or any('text' in o for o in answer.get('options', []) if isinstance(o, dict))


# The pictures that depict no word: a beat strip (its clip says the count) and a place scene (its clip says a sentence).
NON_WORD_PICTURES = ('asset:drum_strip_', 'asset:place_')


def asked(doc):
    """(scored, the item's target word or None, [(option id, the option's word or None, the option's picture or None)]) of an activity
    document. The target is what the item names: its `asks` (a command's word), else its prompt's clip, else the clip of the right option."""
    template = doc.get('template')
    answer = doc.get('answer') or {}
    options = [o for o in answer.get('options', []) if isinstance(o, dict)]
    if template == 'say_it':
        scored = bool(answer.get('scored')) and not answer.get('teach')
        return scored, word_of((doc.get('say') or {}).get('clip')), []
    if answer.get('type') != 'choice' or not options or text_face(doc):
        return False, None, []
    right = [o for o in options if o.get('id') == answer.get('correct')]
    target = word_of(doc.get('asks'))
    if target is None and template == 'tap_answer':
        target = word_of((doc.get('prompt') or {}).get('target'))
    if target is None and template in ('tap_answer', 'puppet_talk') and right:
        target = word_of(right[0].get('clip'))
    return True, target, [(o.get('id'), word_of(o.get('clip')), o.get('sprite')) for o in options]


def story_pages(docs):
    """(the narration clips, the pictures) of the pages of the stories among [docs] (activity documents)."""
    clips, pictures = set(), set()
    for doc in docs:
        if doc.get('template') != 'story':
            continue
        for page in (doc.get('scene') or {}).get('pages', []):
            clips.update(word_of(c) for c in page.get('clips', []))
            if page.get('picture'):
                pictures.add(page['picture'])
    return clips, pictures


class Walk:
    """One course walked as a new learner. [course] is a built tools/lang_pack.py Course."""

    def __init__(self, course):
        self.course = course
        self.findings = []
        self.met = set()
        self.everyday = {word_of(course.vo(c)) for c in course.spec.get('everyday', []) if isinstance(c, str)}
        docs = [info['doc'] for info in course.items.values()]
        self.page_clips, self.page_pictures = story_pages(docs)
        self.not_words = self._not_words(docs)
        self.vocabulary = self._vocabulary(docs)
        self.lessons = self._lessons()

    def _not_words(self, docs):
        """The clips that are pages, counts or sentences: the narration of a story page, and the clip of any option that depicts no word
        (wherever else the course uses the clip, a say step of a place sentence for one, it stays no word)."""
        clips = set(self.page_clips)
        for doc in docs:
            clips.update(word for _, word, picture in asked(doc)[2] if word is not None and self.depicts_no_word(picture))
        return clips

    def _vocabulary(self, docs):
        """Every clip the course names as a word somewhere: the clip of an option that depicts a word, an `asks`, what a say step or a Meet
        screen says. A prompt that is none of these is a carrier (see the module's note)."""
        words = set()
        for doc in docs:
            scored, target, options = asked(doc)
            words.update(word for _, word, picture in options if word is not None and not self.depicts_no_word(picture))
            if doc.get('asks'):
                words.add(word_of(doc['asks']))
            if doc.get('template') == 'say_it':
                words.add(target)
        words.discard(None)
        return words - self.not_words

    def depicts_no_word(self, picture):
        """Is [picture] a beat strip, a place scene or the page of a story: a picture whose clip is a count, a sentence or a page?"""
        return isinstance(picture, str) and (picture.startswith(NON_WORD_PICTURES) or picture in self.page_pictures)

    def is_word(self, clip):
        """Is [clip], the target of an item, a word to meet (and not a story page or a carrier)?"""
        return clip in self.vocabulary

    def _lessons(self):
        """[(sequence, id, document)] of the course in `sequence` order (file order for equal numbers)."""
        out = []
        for n, full in enumerate(self.course.lessons):
            doc = self.course.files_json('lesson.%s.json' % full)
            if doc is not None:
                out.append((doc.get('sequence', 1000), n, full, doc))
        return [(seq, full, doc) for seq, _, full, doc in sorted(out)]

    def add(self, rule, lesson, where, message):
        enforced = rule != 'recall' and (self.course.met_before_mode() == 'enforce' or self.course.lesson_shapes.get(lesson) == 'new')
        self.findings.append(Finding(rule, lesson, where, message, enforced))

    def run(self):
        taught = []  # [(lesson number, word, lesson id)], in the order the words are introduced
        targets = []  # the scored targets of each lesson, in walk order
        for number, (_, full, doc) in enumerate(self.lessons):
            lesson_targets = self._lesson(full, doc, number, taught)
            targets.append(lesson_targets)
        for number, word, full in taught:
            later = targets[number + 1:number + 1 + RECALL_WINDOW]
            if len(later) == RECALL_WINDOW and not any(word in t for t in later):
                self.add('recall', full, word, 'the new word "%s" is not asked again in any of the next %d lessons (a warning)'
                         % (word, RECALL_WINDOW))
        return self.findings

    def _doc(self, aid):
        info = self.course.items.get(aid)
        return info['doc'] if info else None

    def _sequence(self, doc):
        """The lesson's activity ids in play order, each Meet screen standing where its set says: [(kind, id)] with kind `meet` or `item`."""
        items = list(doc.get('items', []))
        at = {}
        for entry in doc.get('teach', []):
            if entry.get('mode', 'teach') != 'teach':
                continue
            before = entry.get('before')
            at.setdefault(items.index(before) if before in items else 0, []).append(entry)
        order = []
        for i, aid in enumerate(items):
            for entry in at.get(i, []):
                order += [('meet', m) for m in entry['items']]
            order.append(('item', aid))
        return order, [e for e in doc.get('teach', []) if e.get('mode', 'teach') == 'teach']

    def _lesson(self, full, doc, number, taught):
        order, sets = self._sequence(doc)
        for entry in sets:
            if len(entry['items']) > MEET_MAX:
                self.add('meet-size', full, ', '.join(entry['items']),
                         'a Meet set has %d words; at most %d (frame 3.5.1)' % (len(entry['items']), MEET_MAX))
        introduced = {}  # word -> the scored items on it so far (aid, number of options)
        scored_here = []
        has_use = False
        for kind, aid in order:
            d = self._doc(aid)
            if d is None:
                continue
            if kind == 'meet':
                word = word_of((d.get('say') or {}).get('clip'))
                if word not in self.met:
                    taught.append((number, word, full))
                    introduced[word] = []
                self.met.add(word)
                continue
            if d.get('template') in USE_TEMPLATES and not (d.get('answer') or {}).get('teach'):
                has_use = has_use or self._is_use(full, doc, aid, d)
            scored, target, options = asked(d)
            if not scored:
                continue
            self._check_item(full, aid, target, options)
            if target is not None:
                scored_here.append((aid, target))
                if target in introduced and self._counts_as_find(full, doc, aid):
                    introduced[target].append(len(options))
        for word, finds in introduced.items():
            if len(finds) < FIND_MIN:
                self.add('find-count', full, word, 'the new word "%s" is the target of %d Find item(s) in its lesson; at least %d'
                         % (word, len(finds), FIND_MIN))
            elif finds[0] > FIRST_FIND_MAX:
                self.add('first-find', full, word, 'the first Find on the new word "%s" has %d choices; at most %d' % (word, finds[0], FIRST_FIND_MAX))
        if not has_use:
            self.add('no-use', full, '', 'the lesson has no Use item (say it, listen and do, a puppet turn or a chant)')
        return {t for _, t in scored_here}

    def _counts_as_find(self, full, doc, aid):
        """In a lesson written in four parts only the items of `find` count; in the old form every scored item on the word does."""
        parts = self.course.lesson_parts.get(full)
        return True if parts is None else parts.get(aid) == 'find'

    def _is_use(self, full, doc, aid, d):
        parts = self.course.lesson_parts.get(full)
        return True if parts is None else parts.get(aid) == 'use'

    def _check_item(self, full, aid, target, options):
        unnamed = [oid for oid, word, picture in options if word is None and picture and not self.depicts_no_word(picture)]
        if unnamed:
            self.add('unnamed', full, aid, '%s: the picture option(s) %s name no word clip, so a touch cannot say them' % (aid, ', '.join(unnamed)))
        words = [target] if target is not None and self.is_word(target) else []
        words += [word for _, word, picture in options if word is not None and not self.depicts_no_word(picture)]
        for word in sorted(set(words)):
            if word not in self.met and word not in self.everyday:
                self.add('not-met', full, aid, '%s asks the word "%s" before any Meet screen has taught it' % (aid, word))


def check(course):
    """Every finding of a built course, in walk order: [Finding]."""
    return Walk(course).run()


def summary(findings):
    """{rule: count} of the findings, in the order of RULES."""
    count = Counter(f.rule for f in findings)
    return {rule: count[rule] for rule in RULES if count[rule]}


def format_report(course_id, findings):
    """The report of one course as lines: the totals, then each finding by lesson. Report mode and enforced findings alike."""
    lines = []
    totals = summary(findings)
    refused = sum(1 for f in findings if f.enforced and f.rule != 'recall')
    words = {m.group(1) for f in findings if f.rule == 'not-met' for m in [re.search('the word "([^"]+)"', f.message)] if m}
    lessons = {f.lesson for f in findings if f.rule != 'recall'}
    lines.append('%s: %d finding(s) (%s); %d distinct word(s) asked and never taught; %d lesson(s) to re-cut; %d would refuse the build now' % (
        course_id, len(findings), ', '.join('%s %d' % kv for kv in totals.items()) or 'none', len(words), len(lessons), refused))
    for f in findings:
        lines.append('  %s%s %s: %s' % ('REFUSED ' if f.enforced and f.rule != 'recall' else '', f.rule, f.lesson, f.message))
    return lines
