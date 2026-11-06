"""The CS Teacher's checker: runs every Robots (CS) activity of the pack on a small simulator (M10 step 0.5).

    python -I tools/check_robot.py                     # every CS item of content/starter
    python -I tools/check_robot.py --band C --strict   # the gate of a Band C batch
    python -I tools/check_robot.py --list              # also print every finding
    python -I tools/check_robot.py --dir <folder>

The simulator is the app's own rule (app/lib/play/robot_path_session.dart): the grid is (column, row) from the top left,
the arrows are absolute and never mirror (up is up, right is right, in every language), a step off the grid or into an
obstacle or through a wall is not taken, and a program is right when the robot ends on the flag.

For a grid task it checks that the intended solution stays on the grid, reaches the flag and fits maxSteps; that it is a
shortest way (breadth-first search over the grid with its obstacles and walls) and that maxSteps leaves room for one; that
"any valid way" is what the app accepts unless the item asks for the shortest (`answer.shortest`), in which case only a
shortest way may pass; that the task fits the band (PLAN.md: 3-step programs in Band A, up to 8 in Band B; a grid of at
most 6 by 4); and that every distractor program (an option with a `program`) fails for a reason the child can see: it
ends on another square, bumps the edge, an obstacle or a wall, or stops short. It also checks the other Robots items:
counting the steps of a row to the flag, the order of a routine (CS-A-01, CS-A-05), and the one wrong step of a program
that should repeat (CS-B-04).

Severities and the exit code are those of tools/check_maths.py: WRONG > RULE > AMBIG > NOTE, and UNCHECKED; exit 1 on a
WRONG or RULE finding (with --strict also AMBIG or UNCHECKED). Python 3 standard library only.
"""
import argparse
import json
import os
import sys
from collections import Counter, deque

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
sys.dont_write_bytecode = True  # no __pycache__ in tools/
import check_maths as cm  # noqa: E402  (the Hebrew reader, the tag rules and the table are shared)

ROOT = cm.ROOT
STARTER = cm.STARTER

MOVES = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}
# robot_path v2 (M10 X10 c): the robot faces a way; forward and back move along it, the turns change it (clockwise order).
HEADINGS = ['up', 'right', 'down', 'left']
TURNS = {'turnLeft': -1, 'turnRight': 1}
RELATIVE = {'forward', 'back'} | set(TURNS)
DIR_WORDS = {'למעלה': 'up', 'למטה': 'down', 'ימינה': 'right', 'שמאלה': 'left'}
# Band A plans 3 steps; Band B up to 8 (PLAN.md › Learners & age bands: gestures); a grid of at most 6 × 4 (the schema).
PLAN_STEPS = {'A': 3, 'B': 8, 'C': 12}
GRID_MAX = {'A': (6, 4), 'B': (6, 4), 'C': (6, 6)}  # M10 X10 (a): Band C grids up to 6 x 6
ROUTINES = {'teeth': ['step_paste', 'step_brush', 'step_rinse'], 'wash': ['step_tap', 'step_soap', 'step_towel']}
ROUTINE_WORDS = {'teeth': 'שנים', 'wash': 'ידים'}


class Grid:
    """A robot task: the grid, the start, the flag, the obstacles and the walls (each wall between two squares)."""

    def __init__(self, scene):
        self.facing = (scene.get('robot') or {}).get('facing', 'up')
        self.cols = scene.get('cols')
        self.rows = scene.get('rows')
        self.start = (scene['robot']['col'], scene['robot']['row'])
        self.goal = (scene['goal']['col'], scene['goal']['row'])
        self.blocked = {(o['col'], o['row']) for o in scene.get('obstacles') or []}
        self.walls = set()
        for w in scene.get('walls') or []:
            a, b = (w['col'], w['row']), (w['col'] + MOVES[w['side']][0], w['row'] + MOVES[w['side']][1])
            self.walls |= {(a, b), (b, a)}

    def inside(self, p):
        return 0 <= p[0] < self.cols and 0 <= p[1] < self.rows

    def step(self, p, d):
        """(the square after the arrow [d], why it did not move or None)."""
        q = (p[0] + MOVES[d][0], p[1] + MOVES[d][1])
        if not self.inside(q):
            return p, 'edge'
        if q in self.blocked:
            return p, 'obstacle'
        if (p, q) in self.walls:
            return p, 'wall'
        return q, None

    def move(self, state, card):
        """(the state after one card, why it did not move or None); a state is (square, heading)."""
        p, h = state
        if card in TURNS:
            return (p, HEADINGS[(HEADINGS.index(h) + TURNS[card]) % 4]), None
        if card in ('forward', 'back'):
            d = h if card == 'forward' else HEADINGS[(HEADINGS.index(h) + 2) % 4]
            q, why = self.step(p, d)
            return (q, h), why
        q, why = self.step(p, card)
        return (q, h), why

    def run(self, program):
        """(where the robot ends, the bumps on the way as (step number, what)); repeat blocks are unrolled."""
        state, bumps = (self.start, self.facing), []
        for k, card in enumerate(expand(program)):
            state, why = self.move(state, card)
            if why:
                bumps.append((k + 1, why))
        return state[0], bumps

    def shortest(self, cards):
        """The fewest cards (of the kinds in [cards]) that take the robot to the flag, or None when there is none."""
        start = (self.start, self.facing)
        seen = {start: 0}
        todo = deque([start])
        while todo:
            st = todo.popleft()
            if st[0] == self.goal:
                return seen[st]
            for c in cards:
                nxt, why = self.move(st, c)
                if not why and nxt not in seen:
                    seen[nxt] = seen[st] + 1
                    todo.append(nxt)
        return None


def expand(program):
    """The cards a program runs, with every `{"repeat": n, "body": [...]}` block unrolled."""
    out = []
    for c in program or []:
        if isinstance(c, dict):
            out += expand(c.get('body') or []) * int(c.get('repeat', 1))
        else:
            out.append(c)
    return out


def card_count(program):
    """The cards a child places: a repeat block counts as one card plus its body."""
    return sum(1 + card_count(c.get('body')) if isinstance(c, dict) else 1 for c in program or [])


def check_path(f, it):
    sc, a = it.scene, it.answer
    g = Grid(sc)
    if not (g.inside(g.start) and g.inside(g.goal)):
        f.add('WRONG', it, 'grid', 'the robot %s or the flag %s is off the %dx%d grid' % (g.start, g.goal, g.cols, g.rows))
        return
    if g.start == g.goal:
        f.add('WRONG', it, 'grid', 'the robot already stands on the flag')
    if g.start in g.blocked or g.goal in g.blocked:
        f.add('WRONG', it, 'grid', 'the robot or the flag stands on an obstacle')
    top_c, top_r = GRID_MAX.get(it.band, (6, 4))
    if g.cols > top_c or g.rows > top_r:
        f.add('RULE', it, 'grid', 'a %dx%d grid; Band %s boards are at most %dx%d' % (g.cols, g.rows, it.band, top_c, top_r))
    sol = a.get('solution') or []
    flat = expand(sol)
    bad = [d for d in flat if d not in MOVES and d not in RELATIVE]
    if bad:
        f.add('WRONG', it, 'solution', 'steps %s are not arrows' % bad)
        return
    end, bumps = g.run(sol)
    if bumps:
        f.add('WRONG', it, 'solution', 'the solution bumps the %s at step %d' % (bumps[0][1], bumps[0][0]))
    if end != g.goal:
        f.add('WRONG', it, 'solution', 'the solution ends on %s, the flag is on %s' % (end, g.goal))
    relative = any(d in RELATIVE for d in flat)
    best = g.shortest(['forward', 'turnLeft', 'turnRight'] if relative else list(MOVES))
    limit = a.get('maxSteps', 8)
    used = card_count(sol)
    looped = len(flat) != len(sol)
    if best is None:
        f.add('WRONG', it, 'unsolvable', 'no way reaches the flag')
        return
    if best > limit:
        f.add('WRONG', it, 'unsolvable', 'the shortest way is %d steps, maxSteps is %d' % (best, limit))
    if used > limit:
        f.add('WRONG', it, 'solution', 'the solution has %d cards, maxSteps is %d' % (used, limit))
    if looped:
        pass  # a loop is shorter to write than the way it walks: "shortest" is about the cards, so the walk is not compared
    elif len(sol) > best:
        sev = 'WRONG' if a.get('shortest') else 'RULE'
        f.add(sev, it, 'detour', 'the solution (the way the hints walk) takes %d steps, the shortest takes %d%s' %
              (len(sol), best, '; the item asks for the shortest' if a.get('shortest') else ''))
    if a.get('mode') == 'predict':
        want = a.get('end') or {}
        given = sc.get('program') or sol
        end, _ = g.run(given)
        if (want.get('col'), want.get('row')) != end:
            f.add('WRONG', it, 'answer', 'the program ends on %s, the item marks %s' % (end, (want.get('col'), want.get('row'))))
    if a.get('mode') == 'debug':
        given = sc.get('program') or []
        end, _ = g.run(given)
        if end == g.goal:
            f.add('WRONG', it, 'debug', 'the program to debug already reaches the flag')
        diff = [k for k, (x, y) in enumerate(zip(given, sol)) if x != y] + list(range(min(len(given), len(sol)),
                                                                                     max(len(given), len(sol))))
        if not 1 <= len(diff) <= int(a.get('bugs', 2)):
            f.add('WRONG', it, 'debug', 'the fix changes cards %s; the item says %s wrong' % (diff, a.get('bugs', '1 or 2')))
    if a.get('mode') in ('plan', 'debug'):
        top = PLAN_STEPS.get(it.band, 8)
        if best > top:
            f.add('RULE', it, 'band', 'a plan of %d steps; Band %s plans at most %d' % (best, it.band, top))
    elif it.band == 'A' and best > PLAN_STEPS['A']:
        f.add('NOTE', it, 'band', 'direct control, %d moves (Band A plans are 3 steps; one arrow at a time is allowed)' % best)
    if not a.get('misconception'):
        f.add('RULE', it, 'tag-missing', 'no tag for the one-off end (M-CS-OFF1)')
    # distractor programs (options with a program, a future predict or choose-the-program item)
    for o in it.options:
        prog = o.get('program')
        if prog is None:
            continue
        end, bumps = g.run(prog)
        right = end == g.goal and not (a.get('shortest') and len(prog) > best)
        if o['id'] == it.correct and not right:
            f.add('WRONG', it, 'answer', 'the right program %s ends on %s' % (o['id'], end))
        if o['id'] != it.correct:
            if right:
                f.add('WRONG', it, 'second-right', 'the distractor %s also reaches the flag' % o['id'])
            elif not bumps and not any(c in MOVES or c in ('forward', 'back') for c in expand(prog)):
                f.add('AMBIG', it, 'invisible', 'the distractor %s never moves the robot, so there is nothing to see fail'
                      % o['id'])


def check_steps_row(f, it):
    """"How many steps from the robot to the flag?" over a row of squares."""
    row = [cm.sprite_info(r)['name'] for r in it.scene.get('row') or []]
    if 'robot' not in row or 'flag' not in row:
        return None
    steps = abs(row.index('flag') - row.index('robot'))
    if row.index('robot') > row.index('flag'):
        f.add('NOTE', it, 'ltr', 'the robot stands right of the flag in a left-to-right row')
    ch = cm.numeric('steps-row', steps, {'given': [steps]}, [steps])
    return ch


def check_routine(f, it):
    """The order of a routine (brush teeth, wash hands), CS-A-01 and CS-A-05."""
    names = [cm.opt_info(o)['name'] for o in it.options]
    cells = [cm.sprite_info(c)['name'] for c in it.scene.get('cells') or []]
    which = next((k for k, w in ROUTINE_WORDS.items() if w in it.words), None)
    if which is None:
        return None
    steps = ROUTINES[which]
    if it.template == 'spot_error':
        odd = [k for k, c in enumerate(cells) if c not in steps]
        order = [c for c in cells if c in steps]
        if order != [s for s in steps if s in order]:
            f.add('WRONG', it, 'answer', 'the routine steps %s are out of order' % order)
        if odd != [it.answer.get('wrong')]:
            f.add('WRONG', it, 'answer', 'the step that does not belong is at %s, the item marks %s' %
                  (odd, it.answer.get('wrong')))
        return 'routine'
    if it.has('בטעות'):
        return cm.Choice('routine-intruder', lambda o: cm.opt_info(o)['name'] not in steps)
    if it.has('קדם'):
        k = 0
    elif it.has('בסוף'):
        k = len(steps) - 1
    elif it.has('באמצע'):
        k = 1
    elif it.has('אחרי'):
        cue = {'משחה': 'step_paste', 'מברשת': 'step_brush', 'סבון': 'step_soap', 'ברז': 'step_tap'}
        here = next((v for w, v in cue.items() if w in it.cap), None)
        if here not in steps:
            return None
        k = steps.index(here) + 1
    else:
        return None
    return cm.Choice('routine-order', lambda o, k=k: cm.opt_info(o)['name'] == steps[k])


def check_repeat(f, it):
    """CS-B-04: a program that should repeat a unit, with one wrong step."""
    if not it.has('לחזר על'):
        return None
    unit_text = it.cap.split('לחזר על', 1)[1].split('.')[0]
    unit = [DIR_WORDS[w] for w in cm.tokens(unit_text) if w in DIR_WORDS]
    cells = [c[4:] for c in it.scene.get('cells') or [] if isinstance(c, str) and c.startswith('dir:')]
    if not unit or len(cells) != len(it.scene.get('cells') or []):
        f.add('UNCHECKED', it, 'repeat', 'no unit or arrows read')
        return 'repeat'
    odd = [k for k, d in enumerate(cells) if d != unit[k % len(unit)]]
    if odd != [it.answer.get('wrong')]:
        f.add('WRONG', it, 'answer', 'repeating %s, the wrong steps are %s; the item marks %s' %
              (unit, odd, it.answer.get('wrong')))
    if len(cells) < 2 * len(unit):
        f.add('AMBIG', it, 'repeat', 'the program shows the unit fewer than two times')
    return 'repeat'


def check(folder=STARTER, band=None, root=ROOT):
    docs, records, skills = cm.load(folder)
    catalogue = cm.catalogue_tags(os.path.join(root, 'docs', 'curriculum.md'))
    f = cm.Findings()
    counts = Counter()
    for doc in docs:
        if doc.get('domain') != 'cs':
            continue
        it = cm.Item(doc)
        if band and it.band != band:
            continue
        counts['items'] += 1
        kind, choice = None, None
        try:
            if it.template == 'robot_path':
                check_path(f, it)
                kind = 'grid'
                counts['simulated'] += 1
            elif isinstance(it.scene.get('robot'), dict) and any('program' in o for o in it.options):
                # choose the program that reaches the flag: the right option's program is the solution
                right = next((o for o in it.options if o['id'] == it.correct), {})
                it.answer = dict(it.answer, solution=right.get('program') or [],
                                 maxSteps=it.answer.get('maxSteps', PLAN_STEPS['C']),
                                 misconception=it.answer.get('misconception') or 'M-CS-OFF1')
                check_path(f, it)
                kind = 'grid-choice'
                counts['simulated'] += 1
            elif it.template == 'spot_error':
                kind = check_repeat(f, it) or check_routine(f, it)
            elif it.options:
                choice = check_steps_row(f, it) or check_routine(f, it)
                if isinstance(choice, cm.Choice):
                    kind = choice.kind
                    rights = [o['id'] for o in it.options if choice.right(o)]
                    if it.correct not in rights:
                        f.add('WRONG', it, 'answer', 'the marked answer %s is not right; right: %s' %
                              (it.correct, rights or 'none'))
                    extra = [r for r in rights if r != it.correct]
                    if extra:
                        f.add('WRONG', it, 'second-right', 'also right: %s' % ', '.join(extra))
                    for o in it.options:
                        cm.check_label(f, it, o)
                else:
                    choice = None
        except (KeyError, IndexError, TypeError, ValueError) as e:
            f.add('UNCHECKED', it, 'error', 'the checker could not read the item (%s: %s)' % (type(e).__name__, e))
            kind = None
        if kind is None:
            f.add('UNCHECKED', it, 'no-rule', 'no rule of this checker understands the item (%s)' % it.template)
        else:
            counts['checked'] += 1
            counts['kind:' + kind] += 1
        limit = cm.BAND_OPTIONS.get(it.band)
        if it.options and limit and len(it.options) > limit:
            f.add('RULE', it, 'options', '%d options; Band %s shows at most %d' % (len(it.options), it.band, limit))
        cm.check_tags(f, it, records, catalogue, skills, choice)
    play = os.path.join(root, 'app', 'lib', 'play')
    for name in ('robot_path_session.dart', 'spot_error_session.dart'):
        p = os.path.join(play, name)
        if os.path.exists(p):
            with open(p, encoding='utf-8') as fh:
                src = fh.read()
            if 'TextDirection.ltr' not in src:
                f.add('WRONG', 'app/lib/play/' + name, 'ltr', 'the arrows have no left-to-right isolate')
    rp = os.path.join(play, 'robot_path_session.dart')
    if os.path.exists(rp):
        with open(rp, encoding='utf-8') as fh:
            src = fh.read()
        if "<String>['left', 'up', 'down', 'right']" not in src:
            f.add('NOTE', 'app/lib/play/robot_path_session.dart', 'ltr', 'the arrow pad order is not left, up, down, right')
    return f.rows, counts


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--dir', default=STARTER)
    ap.add_argument('--band', choices=('A', 'B', 'C'))
    ap.add_argument('--strict', action='store_true')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--json')
    args = ap.parse_args(argv)
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except (AttributeError, ValueError):
        pass
    rows, counts = check(args.dir, args.band)
    rows.sort(key=lambda r: (cm.SEVERITIES.index(r[0]), str(r[1]), r[2]))
    if args.list:
        for s, i, c, m in rows:
            print('%-9s %-24s %-14s %s' % (s, i, c, m))
        print()
    print(cm.table(rows, counts).replace('check_maths: %d maths items' % counts['items'],
                                         'check_robot: %d Robots items, %d grid tasks simulated' %
                                         (counts['items'], counts['simulated'])))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as fh:
            json.dump([dict(zip(('severity', 'id', 'code', 'message'), r)) for r in rows], fh, ensure_ascii=False,
                      indent=1)
    fail = cm.STRICT_FAILING if args.strict else cm.FAILING
    return 1 if any(r[0] in fail for r in rows) else 0


if __name__ == '__main__':
    sys.exit(main())
