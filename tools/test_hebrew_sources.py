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
    **{('activity.b.logb08.%d.json' % k, 'a11y.altText'): (
        alt, 'the alt text is the prompt, and the prompt row is proposed (V1, waits for the owner)')
       for k, alt in enumerate([
           'אִם הַצּוּרָה אֲדֻמָּה, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.',
           'אִם הַצּוּרָה כְּחֻלָּה, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.',
           'אִם הַצּוּרָה עִגּוּל, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.',
           'אִם הַצּוּרָה רִבּוּעַ, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.',
           # B-15 part 2: the triangle and the rectangle, in the form of the other four until the owner decides V1
           'אִם הַצּוּרָה מְשֻׁלָּשׁ, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.',
           'אִם הַצּוּרָה מַלְבֵּן, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.'], start=1)},
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
        # pinned at the regeneration of B-15 part 2 (200 new activities, the alert texts and word lists of main); 1308 became 1302
        # in B-40, when six lines that the table had corrected (the generators already had the corrections) were replaced by
        # new hint lines, which are `proposed` for the owner and need no correction; 1302 became 1205 in B-40 part 4, when 97 more
        # (the Band B hint lines with the dagesh after the vav, שְׁנֵי / שְׁתֵּי and the like, which the table had corrected) were
        # replaced by new lines that carry the corrections already
        self.assertEqual(len(self.rows), 12629)
        self.assertEqual(sum(1 for r in changed if r['status'] in DONE), 1205)
        self.assertEqual(sum(1 for r in changed if r['status'] == 'proposed'), 64)

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
        self.assertEqual(self.a.from_('שָׁלוֹשׁ'), 'מִ' + 'שָׁלוֹשׁ')
        self.assertEqual(self.a.from_('אַרְבַּע'), 'מִאַרְבַּע')  # as the table has it (a question for the editor)

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


if __name__ == '__main__':
    unittest.main()
