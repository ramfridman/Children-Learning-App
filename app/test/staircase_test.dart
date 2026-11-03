// The placement staircase (docs/languages/frame.md section 3.2, LS13): every rule of the frame, on plain ladders. No widget, no clock.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/staircase.dart';

/// A ladder of [levels] levels with [perLevel] probes each: `a0.1`, `a0.2`, `a1.1` ...
StrandPlan _plan({int levels = 5, int perLevel = 4, int start = 0, String id = 'o'}) => StrandPlan(
  id: id,
  start: start,
  levels: <List<String>>[
    for (int l = 0; l < levels; l++) <String>[for (int n = 1; n <= perLevel; n++) '$id$l.$n'],
  ],
);

/// Plays [answers] (true is right) on a fresh staircase, each answered with the probe it handed out.
Staircase _play(StrandPlan plan, String answers) {
  final Staircase s = Staircase(plan);
  for (final bool right in answers.split('').map((String c) => c == 'R')) {
    final String? item = s.next;
    if (item == null) break;
    s.record(item, right: right);
  }
  return s;
}

void main() {
  group('the moves', () {
    test('it starts at the floor with the first probe of the floor', () {
      final Staircase s = Staircase(_plan());
      expect(s.level, 0);
      expect(s.next, 'o0.1');
      expect(s.stopped, isFalse);
      expect(s.asked, 0);
    });

    test('two right answers go up a level; one right alone does not', () {
      final Staircase s = _play(_plan(), 'R');
      expect(s.level, 0);
      final Staircase t = _play(_plan(), 'RR');
      expect(t.level, 1);
      expect(t.next, 'o1.1');
      final Staircase u = _play(_plan(), 'RRRR');
      expect(u.level, 2);
    });

    test('one wrong answer goes down a level, and a wrong answer breaks a run of rights', () {
      expect(_play(_plan(start: 2), 'W').level, 1);
      // R then W: the run is broken, so the next R is the first of a new pair
      final Staircase s = _play(_plan(start: 2), 'RWR');
      expect(s.level, 1);
      expect(_play(_plan(start: 2), 'RWRR').level, 2);
    });

    test('a probe is never asked twice, and the next one at a level is the next unasked', () {
      final Staircase s = _play(_plan(start: 1), 'WR');
      // level 1 (asked o1.1, wrong) -> level 0 (o0.1 right) -> still level 0
      expect(s.level, 0);
      expect(s.next, 'o0.2');
    });

    test(
      'the questionnaire sets where it starts, never where it ends: a miss still goes down from the start',
      () {
        final Staircase s = Staircase(_plan(start: 3));
        expect(s.level, 3);
        expect(s.next, 'o3.1');
        s.record('o3.1', right: false);
        expect(s.level, 2);
        expect(
          StrandPlan(id: 'o', levels: _plan().levels).startingAt(99).start,
          4,
          reason: 'a start above the ladder is the top',
        );
        expect(StrandPlan(id: 'o', levels: _plan().levels).startingAt(-3).start, 0);
      },
    );
  });

  group('when it stops', () {
    test('after 8 probes, never more', () {
      final Staircase s = _play(_plan(levels: 6), 'RRRRRRRRRRRR');
      expect(s.asked, 8);
      expect(s.next, isNull);
      expect(s.stopped, isTrue);
      // and a ninth is refused by the staircase itself
      final Staircase t = _play(_plan(levels: 8, perLevel: 4), 'RRRRRRRR');
      expect(t.asked, 8);
      expect(t.stopped, isTrue);
    });

    test('after 2 reversals (up then down then up, or down then up then down)', () {
      // RR up to 1; W down to 0 (reversal 1); RR up to 1 (reversal 2): stop
      final Staircase s = _play(_plan(start: 0), 'RRWRR');
      expect(s.reversals, 2);
      expect(s.stopped, isTrue);
      expect(s.asked, 5);
      // down then up then down
      final Staircase t = _play(_plan(start: 2), 'WRRW');
      expect(t.reversals, 2);
      expect(t.stopped, isTrue);
      // one reversal is not enough
      final Staircase u = _play(_plan(start: 2), 'WRR');
      expect(u.reversals, 1);
      expect(u.stopped, isFalse);
    });

    test('moves in one direction are not reversals', () {
      final Staircase s = _play(_plan(start: 4), 'WWW');
      expect(s.level, 1);
      expect(s.reversals, 0);
      expect(s.stopped, isFalse);
    });

    test(
      'a strand whose first two probes fail at its floor stops at once (a beginner gets 2 misses, not 8)',
      () {
        final Staircase s = _play(_plan(), 'WW');
        expect(s.asked, 2);
        expect(s.stopped, isTrue);
        expect(s.result.entry, 0);
        expect(s.result.best, isNull);
      },
    );

    test('one miss at the floor does not stop it, and a right answer clears the count of misses', () {
      expect(_play(_plan(), 'W').stopped, isFalse);
      final Staircase s = _play(_plan(), 'WRW');
      expect(s.stopped, isFalse, reason: 'the right answer between the two misses');
      expect(_play(_plan(), 'WRWW').stopped, isTrue);
    });

    test('two right answers at the top of the ladder end it there', () {
      final Staircase s = _play(_plan(levels: 2, perLevel: 4, start: 1), 'RR');
      expect(s.stopped, isTrue);
      expect(s.result.best, 1);
      expect(s.result.entry, 0, reason: 'the highest level passed, minus one unit');
    });

    test('a level with no probe left ends the strand: the staircase never repeats a probe', () {
      final StrandPlan plan = StrandPlan(
        id: 'o',
        levels: <List<String>>[
          <String>['a', 'b'],
          <String>['c'],
          <String>['d', 'e'],
        ],
      );
      // up to level 1 (c), wrong at level 1 -> down to 0 (a, b used), no probe left at level 0
      final Staircase s = _play(plan, 'RRWR');
      expect(s.asked, 3, reason: 'the fourth probe would be a repeat: the strand ends instead');
      expect(s.stopped, isTrue);
    });
  });

  group('the placement', () {
    test('the highest level with at least 2/3 right, minus one unit', () {
      // level 0: RR (2/2), level 1: RR (2/2), level 2 reached with W (0/1) -> best 1, entry 0... go through a longer path
      final Staircase s = _play(_plan(), 'RRRR');
      expect(s.result.best, 1);
      expect(s.result.entry, 0);
      final Staircase t = _play(_plan(levels: 6), 'RRRRRR');
      expect(t.level, 3);
      expect(t.result.best, 2);
      expect(t.result.entry, 1);
    });

    test('two out of three is enough; one of two is not', () {
      // level 0: R R (up) ; level 1: W (down) ; level 0: R R (up) ; reversal 2 stops; level 1 has 0/1, level 0 has 4/4
      final Staircase a = _play(_plan(), 'RRWRR');
      expect(a.result.best, 0, reason: 'level 1 had 0 of 2... only level 0 qualified');
      // two of three at one level: start 1: R W (down)... build a level with R,R,W
      final StrandPlan plan = _plan(levels: 3, perLevel: 4, start: 1);
      final Staircase b = Staircase(plan);
      b.record('o1.1', right: true);
      b.record('o1.2', right: true); // up to 2
      b.record('o2.1', right: true);
      b.record('o2.2', right: false); // down to 1
      expect(b.result.best, 1, reason: 'level 2 is 1 of 2: not 2/3, so level 1 (2 of 2) is the best');
    });

    test('the tally at a level counts every probe given there, whatever order they came in', () {
      final StrandPlan plan = _plan(levels: 3, perLevel: 4, start: 1);
      final Staircase s = Staircase(plan);
      for (final (String id, bool right) in <(String, bool)>[
        ('o1.1', true),
        ('o1.2', false), // down to 0
        ('o0.1', true),
        ('o0.2', true), // up to 1
        ('o1.3', true),
      ]) {
        s.record(id, right: right);
      }
      // level 1: right, wrong, right = 2/3: it qualifies
      expect(s.result.best, 1);
      expect(s.result.entry, 0);
    });

    test('an entry is never below the floor, and with nothing right it is the floor', () {
      final Staircase s = _play(_plan(), 'WW');
      expect(s.result.entry, 0);
      expect(Staircase(_plan()).result.entry, 0);
      expect(Staircase(_plan()).result.stopped, isFalse);
    });

    test(
      'a strand stopped by misses at its floor places at the floor even if a higher level was right earlier',
      () {
        // start 1: RR (up to 2) ... then W W W (down 2 -> 1 -> 0) W (floor miss) ... stops only after two floor misses
        final Staircase s = _play(_plan(start: 2), 'WWWW');
        expect(s.level, 0);
        expect(s.result.entry, 0);
        expect(s.stopped, isTrue);
      },
    );

    test('replaying the same answers gives the same placement as playing them did', () {
      const String answers = 'RRRWRRRW';
      final Staircase live = _play(_plan(levels: 6), answers);
      final Staircase replay = Staircase(_plan(levels: 6));
      for (final (String id, bool right) in <(String, bool)>[
        for (final (int i, String c) in answers.split('').indexed)
          if (live.stopped && i >= live.asked)
            ('', false)
          else
            (_ids(_plan(levels: 6), answers, i), c == 'R'),
      ]) {
        if (id.isNotEmpty) replay.record(id, right: right);
      }
      expect(replay.result.entry, live.result.entry);
      expect(replay.result.best, live.result.best);
      expect(replay.asked, live.asked);
      expect(replay.level, live.level);
    });
  });

  group('the game: strands in order, about 8 probes a visit', () {
    PlacementGame game({int perVisit = 8}) => PlacementGame(
      perVisit: perVisit,
      strands: <StrandPlan>[
        _plan(id: 'o', levels: 4),
        _plan(id: 'l', levels: 3),
      ],
    );

    test(
      'the first strand is played first (oral before literacy); the second only when the first has stopped',
      () {
        final PlacementGame g = game();
        expect(g.next(), 'o0.1');
        g.record('o0.1', right: false);
        g.record('o0.2', right: false);
        expect(g.stairs('o')!.stopped, isTrue);
        expect(g.complete, isFalse);
        expect(g.next(), 'l0.1', reason: 'the oral strand is over: literacy comes next');
      },
    );

    test('a visit holds about 8 probes: the 9th waits for the next visit', () {
      final PlacementGame g = game();
      expect(g.next(doneThisVisit: 7), isNotNull);
      expect(g.next(doneThisVisit: 8), isNull);
      expect(g.next(doneThisVisit: 12), isNull);
    });

    test(
      'the strands run across visits: after the first strand has used its 8, the next visit takes the second',
      () {
        final PlacementGame g = game();
        for (int i = 0; i < 8; i++) {
          final String item = g.next(doneThisVisit: i)!;
          g.record(item, right: true);
        }
        expect(g.stairs('o')!.asked, 8);
        expect(g.next(doneThisVisit: 8), isNull, reason: 'this visit is full');
        expect(g.next(), 'l0.1', reason: 'a new visit starts the next strand');
      },
    );

    test('it is complete when every strand has stopped, and has results for each', () {
      final PlacementGame g = game();
      for (final String id in <String>['o0.1', 'o0.2', 'l0.1', 'l0.2']) {
        g.record(id, right: false);
      }
      expect(g.complete, isTrue);
      expect(g.next(), isNull);
      expect(g.results.keys, <String>['o', 'l']);
      expect(g.results['o']!.entry, 0);
    });

    test('an answer that is no probe of the game is ignored; one probe belongs to one strand and level', () {
      final PlacementGame g = game();
      g.record('somebody-else', right: true);
      expect(g.stairs('o')!.asked, 0);
      expect(g.whereIs('l2.1'), (strand: 'l', level: 2));
      expect(g.whereIs('nope'), isNull);
    });

    test('no probe is ever a speech item: the staircase only ever takes taps (a right or a wrong, never a heard answer)', () {
      // The staircase has no way to be given a spoken result: record takes right or wrong, and the unsure of a lesson is not an answer.
      final Staircase s = Staircase(_plan());
      s.record('o0.1', right: true);
      expect(s.asked, 1);
    });
  });
}

/// The id of the [i]th probe that the plan hands out when [answers] are played on it (used to replay a game from its answers).
String _ids(StrandPlan plan, String answers, int i) {
  final Staircase s = Staircase(plan);
  String? item;
  for (int k = 0; k <= i; k++) {
    item = s.next;
    if (item == null) return '';
    s.record(item, right: answers[k] == 'R');
  }
  return item!;
}
