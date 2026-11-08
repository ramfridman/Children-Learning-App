"""The Hebrew master table (docs/review/hebrew-master.csv) against the sources and the generators (board B-3).

    python tools/test_hebrew_sources.py

* every `text-ready` and `owner-approved` row: the source text is the row's `ui_text` (the corrections are in);
* every `proposed` row: the source text is still the row's `text` (a draft is never brought in before the owner's OK);
* running the generators (tools/regen_content.py) on a copy of the repository gives the committed unit specs and starter
  files, and a second run gives the same bytes again (so a regeneration never brings an old text back).
"""
import csv
import glob
import json
import os
import re
import shutil
import sys
import tempfile
import unicodedata
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
sys.path.insert(0, TOOLS)
import regen_content  # noqa: E402

TABLE = os.path.join(ROOT, 'docs', 'review', 'hebrew-master.csv')
DONE = ('text-ready', 'owner-approved')

# Done rows whose source text is, on purpose, not the table's ui_text yet: (source, id) -> (the text the source has, why).
# Each is checked exactly; remove an entry when its reason is gone.
HELD = {
    # (the six b.logb08 alt texts held here until the logic sweep of 2026-11-06 changed the prompt to the basket, בַּסַּל: their
    # rows are new and proposed, needs-editor, so nothing is held now)
}


def load_rows():
    with open(TABLE, encoding='utf-8-sig', newline='') as fh:
        return list(csv.DictReader(fh))


def dart_strings():
    with open(os.path.join(ROOT, 'app', 'lib', 'strings', 'he.dart'), encoding='utf-8') as fh:
        src = fh.read()
    # the escapes of the source (⁦ and the like) are read as the exporter reads them
    unescape = lambda t: re.sub(r'\\u([0-9a-fA-F]{4})', lambda u: chr(int(u.group(1), 16)), t.replace("\\'", "'"))
    return {m.group(1): unescape(m.group(2))
            for m in re.finditer(r"static const Str (\w+) = Str\(\s*'((?:[^'\\]|\\.)*)'", src)}


def read_json(path):
    with open(path, encoding='utf-8') as fh:
        return json.load(fh)


def path_get(doc, path):
    for key in path.split('.'):
        doc = doc[int(key)] if isinstance(doc, list) else doc[key]
    return doc


class Sources:
    """The current text of a row, read the way tools/export-hebrew-review.py read it."""

    def __init__(self):
        self.he = dart_strings()
        core = read_json(os.path.join(ROOT, 'content', 'lines', 'core.he.json'))
        self.core = {line['id']: line['text'] for line in core['lines']}
        self.tutor = {}
        for f in sorted(glob.glob(os.path.join(ROOT, 'content', 'tutor-lines', '*.json'))):
            # the row id is not unique (the same item, mistake, hint and band twice): rows are matched in file order
            self.tutor[os.path.basename(f)] = [
                ('%s / mistake %s / hint %s / band %s' % (l['item'], l['mistake'], l['hint'], l['band']), l['say'])
                for l in read_json(f)]
        self.words = {}
        self.packs = {}

    def word_list(self, source):
        if source not in self.words:
            with open(os.path.join(ROOT, source), encoding='utf-8') as fh:
                text = fh.read()
            self.words[source] = set(re.findall(r"'([֐-׿][^']*)'", text))
        return self.words[source]

    def pack_file(self, name):
        if name not in self.packs:
            self.packs[name] = read_json(os.path.join(ROOT, 'content', 'starter', name))
        return self.packs[name]

    def texts(self, rows):
        """(row, current text or None) for every row; a word-list row gives the word if the list still has it."""
        tutor_pos = {k: 0 for k in self.tutor}
        out = []
        for r in rows:
            src, rid = r['source'], r['id']
            if src == 'app/lib/strings/he.dart':
                out.append((r, self.he.get(rid)))
            elif src == 'content/lines/core.he.json':
                out.append((r, self.core.get(rid)))
            elif src in self.tutor:
                k = tutor_pos[src]
                tutor_pos[src] += 1
                lid, say = self.tutor[src][k] if k < len(self.tutor[src]) else (None, None)
                out.append((r, say if lid == rid else None))
            elif src.startswith('app/lib/speech/'):
                want = r['ui_text'] if r['status'] in DONE else r['text']
                out.append((r, want if want in self.word_list(src) else None))
            else:
                try:
                    out.append((r, path_get(self.pack_file(src), rid)))
                except (KeyError, IndexError, ValueError, FileNotFoundError):
                    out.append((r, None))
        return out


class HebrewMasterTableTest(unittest.TestCase):
    maxDiff = 2000

    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows()
        cls.current = Sources().texts(cls.rows)

    def test_table_counts(self):
        changed = [r for r in self.rows if r['ui_text'] != r['text']]
        # pinned at the regeneration of B-15 part 2 (200 new activities, the alert texts and word lists of main)
        # 12645 since B-39 (16 bottle and land-name rows added by the hebrew-text-editor)
        # 12757 since L0 (112 rows of he.dart added with the Languages screens: the island, the doors, the parent pages)
        # 14980 since M10 C1 (2,241 rows of 168 activities, 18 lessons, 12 skills and 6 misconceptions, 22 rows of he.dart)
        # 15288 since the math-teacher's C1 QA changes (cd6cc23e), the deferred base-ten, hundred-chart and keypad items (DRAWN) and the hints
        # shortened to 14 words (2026-11-07): new activities and lessons (and the he.dart rows added by the other agents meanwhile)
        # 15704 since the 35 C1 items of 98f57707 (99 new texts, blocks, pay, counting by touch, the middle of two marks), 3 lessons and the he.dart rows of the other agents
        # 15806 since the last C1 items of 2805fbf1 (the estimation line, true-or-false cards, ten-frames, lucky-right items; 144 rows new, 42 gone)
        # 15836 since the two hidden-basket count-on items c.mathb04.11 and .12 (30 rows; the sum-card line replaced vo:fb.card on the sums)
        # 15839 since the lesson field `demo` (vo:demo.ten_is_rod, one row in each of the lessons blocks-tens-and-ones, compare-to-100-more, whole-tens-more)
        # 15823 since the logic sweep was merged (2026-11-08): its reshaped items and wording (one option fewer in LOG-B-06 .5 and .6, no unnamed
        # "friend", the new LOG-A-07 and LOG-B-02 titles, the +2 towers) replace some of C1's rows with other texts
        self.assertEqual(len(self.rows), 15823)
        # 1308 before C1: 19 corrections (מֵאֶפֶס, מֵאַחַת …) are now in the sources; 1296 after the 7 of the deferred items (מַה שֶּׁ, מַה מִּסְתַּתֵּר)
        # 1289 after the hint 3 of 37 Band A and B items was shortened to 14 words (2026-11-07): the 7 rows of b.numb14.1-.4, .7, .8 and b.mathb18.3
        # whose old text still needed a correction (שְׁנַיִם, שְׁלוֹשָׁה, חֲמִשָּׁה …) are now written right by the generator
        # 1283 after the 85 hints that were still over 14 words were shortened (2026-11-07, second pass): 6 more rows (b.mathb01.2-.4, b.mathb09.7,
        # b.numb02.5, math.add.stars) whose old text needed a correction are now written right by their source
        # 1221 after the owner's option A for the two three-coin shop hints (x.mathb17.6, .7; 2026-11-08): their text is now what the source says, so the
        # table no longer counts them as changed (the review CSV was exported again with the new text)
        # 1215 after the owner's answers of 2026-11-08: six rows whose old text needed a correction are now written right by their source (the x.shpb09 "נְדַמְיֵן" line was reworded)
        self.assertEqual(sum(1 for r in changed if r['status'] in DONE), 1215)
        # 18 after the editor sweep of 2026-11-08: the 11 Q2 drafts (the NUM-A-11 pairing line, the NUM-A-07 counting line) are now
        # written in the generators, each with an id of its own (vo:fb.size.pairs, vo:fb.size.count), so the pack says what the table says
        # 6 after the owner approved D12 (2026-11-08): the 12 balance rows (b.mathb13.7-.10) are in the sources
        self.assertEqual(sum(1 for r in changed if r['status'] == 'proposed'), 6)  # 88 before the owner's V1 for M-NL-DIR (2026-11-06): its 44 rows now have the source's final nikud

    def test_done_rows_have_ui_text(self):
        want = lambda r: HELD[(r['source'], r['id'])][0] if (r['source'], r['id']) in HELD else r['ui_text']
        bad = ['%s › %s: %r (want %r)' % (r['source'], r['id'], t, want(r))
               for r, t in self.current if r['status'] in DONE and t != want(r)]
        self.assertFalse(bad, '%d text-ready or owner-approved rows differ:\n%s' % (len(bad), '\n'.join(bad[:40])))

    def test_held_rows_are_done_rows_that_differ(self):
        by_key = {(r['source'], r['id']): r for r in self.rows}
        for key, (text, why) in HELD.items():
            self.assertIn(key, by_key, why)
            self.assertIn(by_key[key]['status'], DONE, key)
            self.assertNotEqual(by_key[key]['ui_text'], text, key)

    def test_proposed_rows_keep_their_text(self):
        bad = ['%s › %s: %r (want %r)' % (r['source'], r['id'], t, r['text'])
               for r, t in self.current if r['status'] == 'proposed' and t != r['text']]
        self.assertFalse(bad, '%d proposed rows changed:\n%s' % (len(bad), '\n'.join(bad[:40])))

    def test_unchanged_rows_keep_their_text(self):
        bad = ['%s › %s' % (r['source'], r['id']) for r, t in self.current if r['status'] == 'unchanged' and t != r['text']]
        self.assertEqual(bad, [])


class PrefixHelpersTest(unittest.TestCase):
    """The pointed one-letter prefixes of tools/author.py (hebrew-notes G2 to G5, G12)."""

    @classmethod
    def setUpClass(cls):
        argv = sys.argv
        sys.argv = argv[:1] + ['-']
        try:
            import author
        finally:
            sys.argv = argv
        cls.a = author

    def test_vav(self):
        v = self.a.vav
        self.assertEqual(v('תֵּשַׁע'), 'וְתֵשַׁע')        # no dagesh in a בגדכפת letter after וְ
        self.assertEqual(v('כָּחֹל'), 'וְכָחֹל')
        self.assertEqual(v('שְׁתַּיִם'), 'וּשְׁתַּיִם')     # וּ before a shva
        self.assertEqual(v('חֲמִשָּׁה'), 'וַחֲמִשָּׁה')      # וַ before a hataf patah
        self.assertEqual(v('יְדַעְתֶּם'), 'וִידַעְתֶּם')     # וִי for a yod with a shva
        self.assertEqual(v('אַרְבַּע'), 'וְאַרְבַּע')
        self.assertEqual(self.a.F[29], 'עֶשְׂרִים וְתֵשַׁע')

    def test_vav_before_a_labial(self):
        # the logic sweep, 2026-11-07: a labial ב ו מ פ takes the shureq whatever its vowel, and ב and פ are soft after it
        v = self.a.vav
        self.assertEqual(v('מִשְׁחָה'), 'וּמִשְׁחָה')
        self.assertEqual(v('מַנְעוּל'), 'וּמַנְעוּל')
        self.assertEqual(v('מַטְבֵּעַ'), 'וּמַטְבֵּעַ')
        self.assertEqual(v('בָּלוֹן'), 'וּבָלוֹן')
        self.assertEqual(v('בַּרְוָז'), 'וּבַרְוָז')
        self.assertEqual(v('פֶּרַח'), 'וּפֶרַח')
        self.assertEqual(v('כּוֹכָב'), 'וְכוֹכָב')  # a letter that is not a labial keeps וְ
        self.assertEqual(v('דָּג'), 'וְדָג')

    def test_prefix(self):
        p = self.a.prefix
        self.assertEqual(p('ב', 'תַּפּוּחַ'), 'בְּתַפּוּחַ')
        self.assertEqual(p('ב', 'שְׁתַּיִם'), 'בִּשְׁתַּיִם')
        self.assertEqual(p('ב', 'עֶשֶׂר'), 'בְּעֶשֶׂר')
        self.assertEqual(p('ב', 'חֲמִשָּׁה שְׁקָלִים'), 'בַּחֲמִשָּׁה שְׁקָלִים')
        self.assertEqual(p('ל', 'דָּג'), 'לְדָג')

    def test_from(self):
        self.assertEqual(self.a.from_('אֶפֶס'), 'מֵאֶפֶס')
        self.assertEqual(self.a.from_('אַחַת'), 'מֵאַחַת')
        self.assertEqual(self.a.from_('הַמִּסְפָּר'), 'מֵהַמִּסְפָּר')
        # decided by the editor on 2026-11-06: מֵ before every guttural (also the number words), מִ doubles the next letter
        self.assertEqual(self.a.from_('אַרְבַּע'), 'מֵאַרְבַּע')
        self.assertEqual(self.a.from_('אַרְבָּעִים'), 'מֵאַרְבָּעִים')
        self.assertEqual(self.a.from_('חָמֵשׁ'), 'מֵחָמֵשׁ')
        self.assertEqual(self.a.from_('חֲמִשִּׁים'), 'מֵחֲמִשִּׁים')
        self.assertEqual(self.a.from_('עֶשֶׂר'), 'מֵעֶשֶׂר')
        self.assertEqual(self.a.from_('שָׁלוֹשׁ'), 'מִשָּׁלוֹשׁ')
        self.assertEqual(self.a.from_('שֵׁשׁ'), 'מִשֵּׁשׁ')
        self.assertEqual(self.a.from_('שִׁבְעִים'), 'מִשִּׁבְעִים')
        self.assertEqual(self.a.from_('תֵּשַׁע'), 'מִתֵּשַׁע')  # already doubled
        self.assertEqual(self.a.from_('שְׁלוֹשִׁים'), 'מִשְּׁלוֹשִׁים')  # the doubling stays under a shva (מִשְּׁנֵי, as the Bible points it; 2026-11-07)
        self.assertEqual(self.a.from_('שְׁמוֹנֶה'), 'מִשְּׁמוֹנֶה')
        self.assertEqual(self.a.from_('תְּשַׁע עֶשְׂרֵה'), 'מִתְּשַׁע עֶשְׂרֵה')  # already doubled

    def test_vav_before_a_prefixed_number(self):
        v, p = self.a.vav, self.a.prefix
        self.assertEqual(v(p('ב', 'שְׁלוֹשִׁים')), 'וּבִשְׁלוֹשִׁים')  # a labial takes the shureq, and is soft after it
        self.assertEqual(v(p('ב', 'אַרְבָּעִים')), 'וּבְאַרְבָּעִים')
        self.assertEqual(v('מַטְבֵּעַ'), 'וּמַטְבֵּעַ')
        self.assertEqual(v('תֵּשַׁע'), 'וְתֵשַׁע')
        self.assertEqual(v('שְׁתַּיִם'), 'וּשְׁתַּיִם')

    def test_robot_steps(self):
        self.assertEqual(self.a.robot_steps(['right', 'right', 'down']), 'שְׁנֵי צְעָדִים לְכִוּוּן הַדֶּגֶל, וְאָז צַעַד אֶחָד לְמַטָּה')
        self.assertEqual(self.a.robot_steps(['left']), 'צַעַד אֶחָד לְכִוּוּן הַדֶּגֶל')


def snapshot(root):
    out = {}
    for sub in ('units', 'starter'):
        base = os.path.join(root, 'content', sub)
        for name in sorted(os.listdir(base)):
            if name.endswith('.json'):
                with open(os.path.join(base, name), 'rb') as fh:
                    out[sub + '/' + name] = fh.read()
    return out


class RegenerationTest(unittest.TestCase):
    def test_generators_reproduce_the_sources_and_are_stable(self):
        with tempfile.TemporaryDirectory() as tmp:
            shutil.copytree(TOOLS, os.path.join(tmp, 'tools'), ignore=shutil.ignore_patterns('__pycache__', 'home_map_src'))
            shutil.copytree(os.path.join(ROOT, 'content'), os.path.join(tmp, 'content'))
            regen_content.run(tmp, quiet=True)
            first = snapshot(tmp)
            committed = snapshot(ROOT)
            self.assertEqual(sorted(first), sorted(committed))
            differ = [k for k in first if first[k] != committed[k]]
            self.assertEqual(differ, [], 'a regeneration changes %d files (run tools/regen_content.py): %s'
                             % (len(differ), differ[:20]))
            regen_content.run(tmp, quiet=True)
            second = snapshot(tmp)
            self.assertEqual([k for k in first if first[k] != second.get(k)], [])


class SweepGuardsTest(unittest.TestCase):
    """Mistakes the editor's sweep of 2026-11-08 found and fixed, kept out by a scan of every Hebrew string of the starter pack, the
    three language courses (pack, course.json, units) and he.dart (docs/agents/hebrew-notes.md section 14)."""

    VAV_BEFORE_SHVA = re.compile('(?<![\u0590-\u05ff])\u05d5\u05b0(?:[\u05d0-\u05ea]\u05b0|\u05d9\u05b0)')      # וְתְ…, וְיְ… (want וּתְ…, וִי…)
    VAV_BEFORE_LABIAL = re.compile('(?<![\u0590-\u05ff])\u05d5\u05b0[\u05d1\u05de\u05e4]')                        # וְמ…, וְב…, וְפ… (want וּ)
    MA_QAMATS = re.compile('(?<![\u0590-\u05ff])\u05de\u05b8\u05d4 [\u05d1\u05d2\u05d3\u05d6\u05d8\u05d9\u05db\u05dc\u05de\u05e0\u05e1\u05e4\u05e6\u05e7\u05e9\u05ea]')   # מָה + a letter that takes the dagesh
    MA_PATAH = re.compile('(?<![\u0590-\u05ff])\u05de\u05b7\u05d4 [\u05d0\u05d4\u05d7\u05e2\u05e8]')            # מַה + a guttural or resh
    BA_ARTICLE = re.compile('(?<![\u0590-\u05ff])\u05d1\u05b7\u05bc\u05d0')                                    # בַּא… (the article before א is בָּ)
    BARE_ZOT = re.compile('(?<![\u0590-\u05ff])\u05d6\u05b9\u05d0\u05ea')                                      # זֹאת without the article: write זוֹ
    BANNED = [('חֲפָצִים', 'a written-register word: דְּבָרִים'), ('חָבֵר כָּתַב', 'an unnamed friend who does something'),
              ('חָבֵר אוֹסֵף', 'an unnamed friend who does something'), ('חָבֵר סָפַר', 'an unnamed friend who does something'),
              ('שֶׁבִּקְשׁוּ', 'who asked? (שֶׁבִּקַּשְׁתִּי or שֶׁמְּבַקְשִׁים)')]

    @classmethod
    def setUpClass(cls):
        cls.texts = []

        def walk(o, where):
            if isinstance(o, str):
                if re.search('[\u0590-\u05ff]', o):
                    cls.texts.append((where, unicodedata.normalize('NFC', o)))
            elif isinstance(o, dict):
                for k, v in o.items():
                    walk(v, where)
            elif isinstance(o, list):
                for v in o:
                    walk(v, where)
        files = sorted(glob.glob(os.path.join(ROOT, 'content', 'starter', '*.json')))
        files += sorted(glob.glob(os.path.join(ROOT, 'content', 'languages', '*', '**', '*.json'), recursive=True))
        for f in files:
            if os.path.basename(f) in ('pack.json', 'voice-plan.json'):
                continue
            walk(read_json(f), os.path.relpath(f, ROOT))
        for k, v in dart_strings().items():
            cls.texts.append(('he.dart ' + k, unicodedata.normalize('NFC', v)))

    def hits(self, pattern):
        return sorted({'%s: %s' % (w, t[:70]) for w, t in self.texts if pattern.search(t)})

    def test_vav_takes_its_vowel_from_the_next_letter(self):
        self.assertEqual(self.hits(self.VAV_BEFORE_SHVA), [])
        self.assertEqual(self.hits(self.VAV_BEFORE_LABIAL), [])

    def test_ma_and_its_dagesh(self):
        self.assertEqual(self.hits(self.MA_QAMATS), [])
        self.assertEqual(self.hits(self.MA_PATAH), [])

    def test_article_after_bet_and_the_written_zot(self):
        self.assertEqual(self.hits(self.BA_ARTICLE), [])
        self.assertEqual(self.hits(self.BARE_ZOT), [])

    def test_words_the_sweep_removed(self):
        bad = ['%s (%s): %s' % (w, why, t[:60]) for w, t in self.texts for word, why in self.BANNED if word in t]
        self.assertEqual(sorted(set(bad)), [])

    def test_course_voice_texts_end_in_a_stop_and_never_shout(self):
        bad = []
        for lang in ('eng', 'heb', 'rus'):
            lines = read_json(os.path.join(ROOT, 'content', 'languages', lang, 'course.json'))['lines']
            for key, line in lines.items():
                v = line.get('voice')
                if v and not key.startswith(('he-gl-', 'gl-')) and (v.rstrip()[-1] not in '.?\u2026:' or '!' in v):
                    bad.append('%s %s: %s' % (lang, key, v))
        self.assertEqual(bad, [])


if __name__ == '__main__':
    unittest.main()
