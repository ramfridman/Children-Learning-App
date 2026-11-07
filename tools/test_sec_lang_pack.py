"""Security-engineer proof tests for tools/lang_pack.py (SEC-BA-1 in docs/security/findings.md).

    python -I tools/test_sec_lang_pack.py

SEC-BA-1: every name the generator writes must stay inside content/languages/<course>/pack. A unit file's `docs` entry
({"kind": "gate", "id": ..., "doc": {...}}) gives the file name `gate.<id>.json` with the id unchecked, so an id with `/` or `\\`
and `..` writes a JSON file of the author's choosing outside the pack folder (for example over a settings file of the repo).
Standard library only; every test works in its own temporary folder.
"""
import os
import sys
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
if TOOLS not in sys.path:  # `python -I` keeps the script's own folder off the path
    sys.path.insert(0, TOOLS)
import lang_pack  # noqa: E402
from test_lang_pack import Sandbox  # noqa: E402


class GeneratedNamesStayInThePackTest(unittest.TestCase):
    def setUp(self):
        self.sb = Sandbox()
        self.addCleanup(self.sb.close)

    def _run(self):
        self.sb.write()
        try:
            lang_pack.run(('eng',), root=self.sb.root, quiet=True)
        except lang_pack.SpecError:
            pass  # refused: nothing is written, which is what is wanted

    def test_a_gate_id_cannot_leave_the_pack_folder(self):
        pack = os.path.normcase(os.path.realpath(os.path.join(self.sb.root, 'content', 'languages', 'eng', 'pack')))
        for sep in ('/', '\\'):
            with self.subTest(sep=sep):
                gate_id = sep.join(['x', '..', '..', '..', '..', '..', 'escaped'])
                escaped = os.path.join(self.sb.root, 'escaped.json')
                if os.path.exists(escaped):
                    os.remove(escaped)  # what the other separator left
                self.sb.unit['docs'] = [{'kind': 'gate', 'id': gate_id, 'doc': {'requires': ['ENG-A-01'], 'holds': ['ENG-B-01']}}]
                self._run()
                self.assertFalse(os.path.exists(escaped), 'the gate id %r wrote %s, outside the pack folder' % (gate_id, escaped))
                for dirpath, _, names in os.walk(self.sb.root):
                    for n in names:
                        if n.startswith('gate.') or n == 'escaped.json':
                            where = os.path.normcase(os.path.realpath(dirpath))
                            self.assertEqual(where, pack, 'a gate file was written outside the pack folder: %s' % os.path.join(dirpath, n))

    def test_a_gate_id_is_held_to_the_gate_schema_before_anything_is_written(self):
        self.sb.unit['docs'] = [{'kind': 'gate', 'id': '../eng.oral', 'doc': {'requires': ['ENG-A-01'], 'holds': ['ENG-B-01']}}]
        self.assertIn('id', self.sb.problems(), 'a gate id that is not a plain id must be a problem of the course files')


if __name__ == '__main__':
    unittest.main()
