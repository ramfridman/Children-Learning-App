"""Band C of the six lands (M10): the unit specs, written from compact tables, the way tools/band_b.py writes Band B's. Then run
tools/author.py on each spec (tools/regen_content.py does both, in the one order that reproduces the committed files).

    python tools/band_c.py            # writes the specs of the batches that have tables
    python tools/band_c.py C1 C2      # only those batches

This is the skeleton (M10 step 0.4): the unit class, the batch registry, the helpers a table needs for the new items (a number
sentence in tokens, a number-entry item), and nothing else. There is no content in it. Each batch adds its tables in step 2 of its
nine steps (docs/milestones/M10.md section 10), from the batch spec of the curriculum-expert and the checked item tables of the
maths and CS teachers; a table is a function that fills one unit and is registered with @table:

    @table('C1', 'numbers', assets=['apple'])
    def numbers_c1(u):
        u.skill('NUM-C-01', 'title', 'line for the child', 'cone-tree', ['NUM-B-02'], ['pictorial', 'symbolic'], tags=['M-CNT-DECADE'])
        number_item(u, 'NUM-C-01', 'the question', [39, '+', 1, '=', '?'], 40, {30: 'M-CNT-DECADE'}, h2='...', h3='...', ok='...')
        u.lesson('count-on-1', 'title', ['NUM-C-01'], [...], 'celebration')

Every Hebrew text is a draft by the table's author and stays `needs-editor` until the hebrew-text-editor makes it `text-ready`; this
file writes none of its own. Nothing is voiced here (owner, 2026-11-06).
"""
import os
import sys

ARGS = sys.argv[1:]  # band_b sets sys.argv for author.py, which is imported and never run: the batches asked for are read first
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from band_b import Unit, write_all  # noqa: E402
from author import NUMBER_MAX, NUMBER_RULES  # noqa: E402,F401

BATCHES = ('C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9')

# Where a batch's lessons start on the path of their land: after Band A (from 1) and Band B (from 30, the extras from 60). The lessons
# of a batch are numbered up from here in the order of the table, so a land's path walks batch by batch, and the path gate (E0) holds a
# lesson back until its skills are unlocked.
FIRST_SEQUENCE_C1 = 100
SEQUENCE_STEP = 30

# The signs a row or a cell may hold (the validator's `op:` tokens) and what they are called in a table.
SIGNS = ('+', '-', 'x', ':', '=', '<', '>', '(', ')')


def first_sequence(batch):
    return FIRST_SEQUENCE_C1 + SEQUENCE_STEP * BATCHES.index(batch)


class UnitC(Unit):
    """One Band C unit: the lessons of one batch in one land. Like a Band B unit, with the band C, the batch in its name
    (`band-c1-numbers`), the activity ids from `c.` (`c.numc01.1`), and its lessons on the path from the batch's first sequence."""
    BAND = 'C'
    OWN_SPECS = 'band-c'

    def __init__(self, batch, domain, note, assets=(), globs=(), first_seq=None):
        assert batch in BATCHES, 'unknown batch %r' % (batch,)
        name = 'band-%s-%s' % (batch.lower(), domain)
        super().__init__(name, domain, note, first_seq or first_sequence(batch), assets=assets, globs=globs, prefix='c')
        self.batch = batch


# The tables, in the order they were registered: (batch, domain, builder, keywords of the unit).
TABLES = []


def table(batch, domain, **unit):
    """Registers the table of one unit: the function fills the UnitC it is given (skills, tags, items, lessons)."""
    def register(build):
        TABLES.append((batch, domain, build, unit))
        return build
    return register


def tokens(*parts):
    """A number sentence as the row tokens of a tap_answer: an int is a number (`n:52`), a sign is `op:`, '?' is the gap.

        tokens(52, '-', 27, '=', '?')  ->  ['n:52', 'op:-', 'n:27', 'op:=', '?']

    A number is at most NUMBER_MAX (10,000); a sign is one of SIGNS."""
    out = []
    for p in parts:
        if p == '?':
            out.append('?')
        elif isinstance(p, int) and not isinstance(p, bool):
            assert 0 <= p <= NUMBER_MAX, '%r is not a number to %d' % (p, NUMBER_MAX)
            out.append('n:%d' % p)
        else:
            assert p in SIGNS, '%r is not a sign of a number sentence' % (p,)
            out.append('op:%s' % p)
    return out


def number_item(u, skill, prompt, row, value, expected=None, rules=None, h2=None, h3=None, ok=None, **kw):
    """A number-entry item (X3): the child types the number that makes the row true. `row` is a list of parts for `tokens`; `expected`
    is {wrong number: tag} for the wrong numbers the author expects; `rules` is {rule: tag} (author.NUMBER_RULES) for the classifiers
    that name any other wrong number. `h2` and `h3` are the harder hints and `ok` the line for the right answer: all text of the table."""
    return u.act(skill, 'number', prompt=prompt, row=tokens(*row), value=value, expected=dict(expected or {}),
                 rules=dict(rules or {}), h2=h2, h3=h3, correct_text=ok, **kw)


def make(batches=None):
    """Runs the registered tables of [batches] (all when None) into units and queues them for writing; returns the units made."""
    made = []
    for batch, domain, build, unit in TABLES:
        if batches and batch not in batches:
            continue
        own = dict(unit)
        u = UnitC(batch, domain, own.pop('note', 'Band C, batch %s. Hebrew is a draft, needs-editor.' % batch), **own)
        build(u)
        u.save()
        made.append(u)
    return made


def main(argv):
    batches = [b.upper() for b in argv]
    for b in batches:
        assert b in BATCHES, 'unknown batch %r (batches are %s)' % (b, ' '.join(BATCHES))
    made = make(batches or None)
    write_all()
    if not made:
        print('band_c: no table is registered yet; nothing written')


if __name__ == '__main__':
    main(ARGS)
