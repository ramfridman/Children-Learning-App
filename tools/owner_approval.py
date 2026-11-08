"""The owner's bulk approval of the Hebrew rows, pinned to a snapshot (docs/review/owner-approval-2026-11-08.csv).

The hebrew-text-editor marks a row `text-ready` (or `proposed`, when the voice text keeps a nikud for the owner to confirm); only the
owner makes it `owner-approved`, and that is the status `voice_gen` needs before it voices a line. This module lets him do it in one
step without ever approving a text he has not seen:

  1. `python -I -X utf8 tools/hebrew_voice_review.py --approval-snapshot docs/review/owner-approval-2026-11-08.csv` writes the list
     of every row that is `text-ready` or `proposed` now: its source, its id and the sha256 of its exact text, ui_text and voice_text.
     It writes a short summary next to it (the same name, `.md`): counts and a sample of voiced lines for the owner to read.
  2. A row is `owner-approved` by the snapshot only while its hash still matches. An edit of the row drops it back to
     `text-ready` (or `proposed`) on the next run, so a changed line needs a new approval. A row that is not in the file is untouched.
  3. The snapshot counts as the owner's word only when `CONFIG` below names it and holds its own sha256 and a date. Nothing in
     this file approves anything while those two are empty.
"""
import csv
import hashlib
import os
import re
from collections import Counter
from typing import NamedTuple

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')

# THE SWITCH. It is OFF: `sha256` and `date` are empty, so no row is approved by the snapshot.
# To switch it on, the orchestrator fills in both (the date the owner said yes, and the sha256 that
# `--approval-snapshot` printed for the snapshot file) after the owner has said yes in chat. Both or neither: a half-filled switch is an
# error. If the file is later changed or written again, its sha256 no longer matches and the next run stops with an error.
# owner approved in chat, 2026-11-08, relayed by the orchestrator
CONFIG = {
    'file': 'docs/review/owner-approval-2026-11-08.csv',
    'sha256': 'f19724a7337cc62d82d0fb8cdcbf74d612207137a622c6c82847e2e26f29640a',  # owner approved in chat, 2026-11-08, relayed by the orchestrator
    'date': '2026-11-08',
}

# The words that end the comment of a row this module approved. The master table keeps the status of a row the owner approved, so
# this mark tells the next run that the status is the snapshot's and has to be worked out again (a changed row falls back).
MARK_PREFIX = '[snapshot-approved '
MARK = re.compile(r' ?\[snapshot-approved [^\]]*\]')
CANDIDATE_STATUSES = ('text-ready', 'proposed')
SEPARATOR = '\x1f'  # between the three texts of the hash, so that moving a character from one to the next changes it


class ApprovalError(Exception):
    """The switch is half filled, or the snapshot is not the file the owner approved."""


class Approval(NamedTuple):
    keys: frozenset  # of (source, id, hash)
    date: str
    name: str  # the file name of the snapshot


def row_hash(text, ui_text, voice_text):
    """sha256 (hex) of the exact original text, screen text and voice text of a row."""
    return hashlib.sha256(SEPARATOR.join((text, ui_text, voice_text)).encode('utf-8')).hexdigest()


def file_sha256(path):
    """sha256 of a file with its line ends read as LF, so that a Windows checkout and a Linux one give the same value."""
    with open(path, 'rb') as fh:
        return hashlib.sha256(fh.read().replace(b'\r\n', b'\n')).hexdigest()


def load_approval(config=None, root=ROOT):
    """The snapshot as the owner's approval, or None while the switch is off. Raises ApprovalError when it is half on or the
    file is not the one named by its sha256."""
    config = CONFIG if config is None else config
    sha, date = config.get('sha256', '').strip(), config.get('date', '').strip()
    if not sha and not date:
        return None
    if not (sha and date):
        raise ApprovalError('the approval switch needs both the date and the sha256 (owner_approval.CONFIG), or neither')
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', date) or not re.fullmatch(r'[0-9a-f]{64}', sha):
        raise ApprovalError('the approval switch: the date must be YYYY-MM-DD and the sha256 64 lower-case hex digits')
    path = os.path.join(root, config['file'])
    if not os.path.exists(path):
        raise ApprovalError('the approval snapshot %s is missing' % config['file'])
    actual = file_sha256(path)
    if actual != sha:
        raise ApprovalError('the approval snapshot %s is not the file the owner approved (sha256 %s, expected %s)'
                            % (config['file'], actual, sha))
    with open(path, encoding='utf-8', newline='') as fh:
        rows = list(csv.reader(fh))
    if not rows or rows[0] != ['source', 'id', 'hash']:
        raise ApprovalError('the approval snapshot %s has no source, id, hash header' % config['file'])
    keys = frozenset((src, rid, h) for src, rid, h in rows[1:])
    return Approval(keys, date, os.path.basename(path))


def approves(approval, source, row_id, text, ui_text, voice_text):
    """True when the snapshot holds this row with exactly this text, screen text and voice text."""
    return approval is not None and (source, row_id, row_hash(text, ui_text, voice_text)) in approval.keys


def mark(approval):
    return ' [snapshot-approved %s %s]' % (approval.date, approval.name)


def is_marked(comment):
    return MARK_PREFIX in comment


def candidates(master_rows):
    """The rows the snapshot lists: those that are `text-ready` or `proposed` before the snapshot itself is applied."""
    return [r for r in master_rows if r['base_status'] in CANDIDATE_STATUSES]


def write_snapshot(master_rows, path):
    """Writes the snapshot file (source, id, hash; one line for each candidate row, in a fixed order, LF line ends), then the
    summary next to it. Returns the sha256 of the snapshot to put in CONFIG."""
    rows = candidates(master_rows)
    entries = sorted((r['source'], r['id'], row_hash(r['text'], r['ui_text'], r['voice_text'])) for r in rows)
    with open(path, 'w', encoding='utf-8', newline='') as fh:
        w = csv.writer(fh, lineterminator='\n')
        w.writerow(['source', 'id', 'hash'])
        w.writerows(entries)
    sha = file_sha256(path)
    with open(os.path.splitext(path)[0] + '.md', 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(summary(rows, os.path.basename(path), sha))
    return sha


def voiced_sample(rows, count=20):
    """`count` spoken rows with different voice texts, spread evenly over the table (in the order of source and id): the same
    ones on every run."""
    first_with_text = {}
    for r in sorted((r for r in rows if r['spoken'] == 'yes' and r['voice_text']), key=lambda r: (r['source'], r['id'])):
        first_with_text.setdefault(r['voice_text'], r)
    spoken = list(first_with_text.values())
    if len(spoken) <= count:
        return spoken
    return [spoken[i * len(spoken) // count] for i in range(count)]


def summary(rows, name, sha):
    """The page the owner reads before he says yes."""
    spoken_rows = [r for r in rows if r['spoken'] == 'yes']
    by_status = Counter(r['base_status'] for r in rows)
    out = ['# Owner approval snapshot: %s\n' % name,
           'Made by `python -I -X utf8 tools/hebrew_voice_review.py --approval-snapshot docs/review/%s`. It lists every row of '
           '`hebrew-master.csv` that is `text-ready` or `proposed`. If the owner says yes, the orchestrator puts the sha256 below and '
           'the date in `CONFIG` of `tools/owner_approval.py`; from then on each listed row is `owner-approved` while its text, screen '
           'text and voice text are exactly what they are now. A row that is edited falls back and needs a new approval.\n' % name,
           'sha256 of the snapshot file: `%s`\n' % sha,
           '## Counts\n',
           '- rows in the snapshot: %d (`text-ready` %d, `proposed` %d)' % (len(rows), by_status['text-ready'], by_status['proposed']),
           '- spoken (a voice says it): %d; not spoken (screen only): %d\n' % (len(spoken_rows), len(rows) - len(spoken_rows)),
           '| group | text-ready, spoken | text-ready, not spoken | proposed, spoken | proposed, not spoken | all |',
           '|---|---|---|---|---|---|']
    groups = sorted({r['group'] for r in rows})
    cell = Counter((r['group'], r['base_status'], r['spoken']) for r in rows)
    for g in groups:
        c = [cell[(g, s, sp)] for s in CANDIDATE_STATUSES for sp in ('yes', 'no')]
        out.append('| %s | %d | %d | %d | %d | %d |' % ((g,) + tuple(c) + (sum(c),)))
    out.append('')
    proposed = [r for r in rows if r['base_status'] == 'proposed']
    if proposed:
        out += ['## Why the %d `proposed` rows were still waiting\n' % len(proposed)]
        for why, n in Counter(re.sub(r'^\[editor\] ', '', r['comment'])[:100].strip() for r in proposed).most_common():
            out.append('- %d: %s' % (n, why))
        out.append('')
    unsourced = [r for r in rows if r['ui_text'] != r['text'] and r['base_status'] == 'proposed']
    if unsourced:
        out += ['## Proposed rows whose screen text is not in the pack yet (%d)\n' % len(unsourced),
                'The voice text is approved with the rest, but the pack still has the old screen text until the generator is changed.\n']
        out += ['- `%s` `%s`' % (r['source'], r['id']) for r in unsourced]
        out.append('')
    out += ['## A sample of %d voiced lines\n' % min(20, len(voiced_sample(rows))),
            'Spoken rows with different voice texts (%d in all), spread evenly over the table (order of source and id). Each shows '
            'the text sent to the voice.\n' % len({r['voice_text'] for r in spoken_rows if r['voice_text']}),
            '| status | source | id | voice text |', '|---|---|---|---|']
    esc = lambda s: s.replace('|', '\\|').replace('\n', ' ')
    for r in voiced_sample(rows):
        out.append('| %s | %s | %s | %s |' % (r['base_status'], esc(r['source']), esc(r['id']), esc(r['voice_text'])))
    out.append('')
    return '\n'.join(out)
