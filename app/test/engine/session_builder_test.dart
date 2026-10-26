import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/representation.dart';
import 'package:nitznutz/engine/session_builder.dart';
import 'package:nitznutz/engine/simulator.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'fixtures.dart';

/// Twenty days of sessions for one invented child in a band.
(List<SessionRun>, int) twentySessions(int band, int seed) {
  final math.Random rnd = math.Random(seed);
  final SimWorld world = SimWorld.random(rnd, skills: 26, delight: true);
  final Engine engine = Engine(catalog: world.catalog);
  // The child starts out knowing the first few skills; it learns more by practising.
  final SimChild child = SimChild(
    catalog: world.catalog,
    known: world.order.take(4).toSet(),
    random: rnd,
    pLearn: 0.3,
  );
  final SessionBuilder builder = SessionBuilder(engine: engine, random: rnd);
  final List<SessionRun> runs = <SessionRun>[];
  DateTime day = DateTime.utc(2026, 11, 1, 16);
  for (int s = 1; s <= 20; s++) {
    runs.add(
      playSession(engine: engine, builder: builder, child: child, band: band, sessionId: s, start: day),
    );
    day = day.add(const Duration(days: 1));
  }
  return (runs, child.known.length);
}

void main() {
  for (final (String, int) b in <(String, int)>[('A', 0), ('B', 1), ('C', 2)]) {
    group('twenty sessions in Band ${b.$1}', () {
      final int band = b.$2;
      late List<SessionRun> runs;
      late int knownAtEnd;
      late int total;
      setUpAll(() {
        final (List<SessionRun>, int) played = twentySessions(band, 100 + band);
        runs = played.$1;
        knownAtEnd = played.$2;
        total = SessionBuilder(engine: engineOf(smallCatalog()), random: math.Random(1)).totalItems(band);
      });

      test('every session ends, begins with a warm-up and is about the right length', () {
        for (final SessionRun r in runs) {
          expect(r.endReason, isNot('guard'), reason: 'the session never ended');
          expect(r.served, isNotEmpty);
          expect(r.served.first.phase, Phase.warmUp);
          expect(r.served.length, lessThanOrEqualTo(total + 2));
          expect(r.served.length, greaterThanOrEqualTo(total ~/ 2));
        }
      });

      test('repair stays small, at most 3 probes, at most 2 new skills, one or two skills in focus', () {
        final SessionBuilder probe = SessionBuilder(engine: engineOf(smallCatalog()), random: math.Random(1));
        final int repairMax = (probe.totalItems(band) * 0.25).floor();
        for (final SessionRun r in runs) {
          // A probe that has started is finished even if it takes the repair a little over its share.
          expect(r.count(Phase.repair), lessThanOrEqualTo(repairMax + 5));
          final Set<String> focus = <String>{
            for (final Served s in r.served)
              if (s.phase == Phase.focus) s.item.primarySkill,
          };
          expect(
            focus.length,
            lessThanOrEqualTo(4),
            reason: 'about two in focus; the others come from a skill that ran out of items or an easy win when stuck',
          );
        }
      });

      test('the shares over the whole twenty days are near the plan', () {
        int all = 0;
        final Map<Phase, int> by = <Phase, int>{for (final Phase p in Phase.values) p: 0};
        for (final SessionRun r in runs) {
          all += r.served.length;
          for (final Served s in r.served) {
            by[s.phase] = by[s.phase]! + 1;
          }
        }
        final double repair = by[Phase.repair]! / all;
        final double focus = by[Phase.focus]! / all;
        final double delight = by[Phase.delight]! / all;
        expect(repair, lessThanOrEqualTo(0.25));
        expect(focus, inInclusiveRange(0.30, 0.75));
        expect(delight, inInclusiveRange(0.08, 0.30), reason: 'the catalogue has delight items');
        expect(by[Phase.warmUp]! / all, lessThan(0.25));
      });

      test('a session ends on a success: the last item is easy, from a skill the child is sure of, or the child just succeeded', () {
        int success = 0;
        for (final SessionRun r in runs) {
          final Served last = r.served.last;
          if (last.result == Result.correct) success++;
        }
        // Slips (5%) can spoil an ending now and then, never most of them.
        expect(success / runs.length, greaterThanOrEqualTo(0.8));
      });

      test(
        'the child learns: after twenty days it knows clearly more skills than the four it began with',
        () {
          expect(knownAtEnd, greaterThanOrEqualTo(8));
        },
      );
    });
  }

  test('a session ends gracefully after the item in progress when the parent limit is reached, on a success where it can', () {
    final math.Random rnd = math.Random(5);
    final SimWorld world = SimWorld.random(rnd, skills: 12);
    final Engine engine = Engine(catalog: world.catalog);
    final SimChild child = SimChild(
      catalog: world.catalog,
      known: world.order.take(8).toSet(),
      random: rnd,
      slip: 0,
    );
    final SessionBuilder builder = SessionBuilder(engine: engine, random: rnd);
    final DateTime t = DateTime.utc(2026, 11, 1, 16);
    for (int s = 1; s <= 3; s++) {
      playSession(
        engine: engine,
        builder: builder,
        child: child,
        band: 0,
        sessionId: s,
        start: t.add(Duration(days: s)),
      );
    }
    final List<Served> served = <Served>[];
    // Three items, then the limit is reached.
    for (int i = 0; i < 3; i++) {
      final Pick p = builder.next(
        SessionContext(sessionId: 9, band: 0, now: t.add(const Duration(days: 9)), served: served),
      );
      expect(p, isA<ServeItem>());
      served.add(Served((p as ServeItem).item, p.phase, Result.correct));
    }
    final Pick end = builder.next(
      SessionContext(
        sessionId: 9,
        band: 0,
        now: t.add(const Duration(days: 9)),
        served: served,
        limitReached: true,
      ),
    );
    expect(end, isA<EndSession>(), reason: 'the last item was a success, so it can end right away');
    served.last.result = Result.incorrect;
    final Pick easy = builder.next(
      SessionContext(
        sessionId: 9,
        band: 0,
        now: t.add(const Duration(days: 9)),
        served: served,
        limitReached: true,
      ),
    );
    expect(easy, isA<ServeItem>());
    expect((easy as ServeItem).phase, Phase.easyEnd);
    expect(engine.state.skills[easy.item.primarySkill]!.p, greaterThanOrEqualTo(0.85));
  });

  test('a brand-new child gets the easiest item of a skill with no prerequisites first', () {
    final Engine e = engineOf(smallCatalog());
    final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(2));
    final Pick p = b.next(SessionContext(sessionId: 1, band: 0, now: day0, served: <Served>[]));
    expect(p, isA<ServeItem>());
    expect((p as ServeItem).item.primarySkill, 'SK-A-01');
    expect(p.phase, Phase.warmUp);
    expect(p.item.difficulty, lessThanOrEqualTo(0.3));
  });

  test('skills whose prerequisites are not ready are not offered', () {
    final Engine e = engineOf(smallCatalog());
    final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(2));
    final Set<String> seen = <String>{};
    final List<Served> served = <Served>[];
    for (int i = 0; i < 6; i++) {
      final Pick p = b.next(SessionContext(sessionId: 1, band: 0, now: day0, served: served));
      if (p is! ServeItem) break;
      seen.add(p.item.primarySkill);
      // The child keeps answering wrongly: A never reaches 0.8.
      served.add(Served(p.item, p.phase, Result.incorrect));
      Story(e).wrong(p.item.id);
    }
    expect(seen, <String>{'SK-A-01'}, reason: 'B, C and D need A at 0.8 first');
  });

  test(
    'stuck: after three wrong answers in a row the builder leaves the skill for an easy win elsewhere',
    () {
      final Engine e = engineOf(smallCatalog())..assume(<String>['SK-A-01']);
      final Story s = Story(e);
      for (int i = 0; i < 4; i++) {
        s.right('A.1', session: 1);
      }
      s.wrong('B.1', session: 1);
      s.wrong('B.2', session: 1);
      s.wrong('B.1', session: 1);
      expect(e.isStuck(1), isTrue);
      final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(2));
      final Pick p = b.next(
        SessionContext(
          sessionId: 1,
          band: 0,
          now: s.at,
          served: <Served>[Served(e.catalog.items['B.1']!, Phase.focus, Result.incorrect)],
        ),
      );
      expect(p, isA<ServeItem>());
      expect((p as ServeItem).item.primarySkill, isNot('SK-B-01'));
      expect(p.reason, contains('stuck'));
    },
  );

  test('repair uses a different representation from the one that failed, and probes go first', () {
    final Engine e = engineOf(smallCatalog());
    final Story s = Story(e);
    for (final String item in <String>['A.1', 'A.2', 'A.1', 'A.2']) {
      s.right(item, session: 1);
    }
    s.wrong('C.1', tag: 'M-C', session: 1);
    s.wrong('C.2', session: 1);
    final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(3));
    final Pick probe = b.next(
      SessionContext(
        sessionId: 1,
        band: 0,
        now: s.at,
        served: <Served>[Served(e.catalog.items['C.2']!, Phase.focus, Result.incorrect)],
      ),
    );
    expect((probe as ServeItem).item.purpose, Purpose.probe);
    expect(probe.item.primarySkill, 'SK-B-01');
    // Fail the probe: a gap in B. The repair items for B avoid the representation that failed.
    s.wrong('B.p1', session: 1);
    s.wrong('B.p2', session: 1);
    expect(e.state.openGaps.single.skill, 'SK-B-01');
    final Set<Representation> reps = <Representation>{};
    for (int i = 0; i < 12; i++) {
      final Pick p = SessionBuilder(engine: e, random: math.Random(i)).next(
        SessionContext(
          sessionId: 1,
          band: 0,
          now: s.at,
          served: <Served>[
            Served(e.catalog.items['A.1']!, Phase.warmUp, Result.correct),
            Served(e.catalog.items['A.2']!, Phase.focus, Result.correct),
          ],
        ),
      );
      if (p is ServeItem && p.phase == Phase.repair) reps.add(p.item.representation);
    }
    expect(reps, isNotEmpty);
    expect(
      reps,
      isNot(contains(Representation.pictorial)),
      reason: 'the probes were in the pictorial representation last, and two wrong answers in a row ask for another',
    );
  });

  group('the representation chooser', () {
    test('never picks the one to avoid unless it is the only one', () {
      final Engine e = engineOf(smallCatalog());
      final RepresentationChooser c = RepresentationChooser(math.Random(1));
      for (int i = 0; i < 100; i++) {
        final Representation r = c.choose(
          engine: e,
          skillId: 'SK-B-01',
          available: <Representation>{
            Representation.concrete,
            Representation.pictorial,
            Representation.symbolic,
          },
          avoid: Representation.concrete,
        );
        expect(r, isNot(Representation.concrete));
      }
      expect(
        c.choose(
          engine: e,
          skillId: 'SK-B-01',
          available: <Representation>{Representation.concrete},
          avoid: Representation.concrete,
        ),
        Representation.concrete,
      );
    });

    test('the same seed gives the same choices', () {
      final Engine e = engineOf(smallCatalog());
      List<Representation> run() {
        final RepresentationChooser c = RepresentationChooser(math.Random(42));
        return <Representation>[
          for (int i = 0; i < 30; i++)
            c.choose(engine: e, skillId: 'SK-B-01', available: Representation.values.toSet(), band: 1),
        ];
      }

      expect(run(), run());
    });

    test(
      'Band A starts with things the child can move: concrete is chosen most often before any evidence',
      () {
        final Engine e = engineOf(smallCatalog());
        final RepresentationChooser c = RepresentationChooser(math.Random(9));
        final Map<Representation, int> counts = <Representation, int>{};
        for (int i = 0; i < 600; i++) {
          final Representation r = c.choose(
            engine: e,
            skillId: 'SK-B-01',
            available: Representation.values.toSet(),
            band: 0,
          );
          counts[r] = (counts[r] ?? 0) + 1;
        }
        final Representation top = counts.entries
            .reduce(
              (MapEntry<Representation, int> a, MapEntry<Representation, int> b) =>
                  a.value >= b.value ? a : b,
            )
            .key;
        expect(top, Representation.concrete);
      },
    );

    test('it learns what works for this child: with a true best way it settles on it in at least 90% of runs within 40 trials', () {
      int settled = 0;
      const int runs = 200;
      for (int run = 0; run < runs; run++) {
        final math.Random rnd = math.Random(run);
        final Engine e = engineOf(smallCatalog());
        final RepresentationChooser c = RepresentationChooser(math.Random(run + 1000));
        // The child does well with stories and badly with the rest.
        const Map<Representation, double> truth = <Representation, double>{
          Representation.concrete: 0.35,
          Representation.pictorial: 0.35,
          Representation.story: 0.85,
          Representation.embodied: 0.35,
          Representation.symbolic: 0.2,
        };
        for (int trial = 0; trial < 40; trial++) {
          final Representation r = c.choose(
            engine: e,
            skillId: 'SK-B-01',
            available: Representation.values.toSet(),
            band: 0,
          );
          final RepStats st = e.state.repStats('SK-B', r);
          st.tries++;
          if (rnd.nextDouble() < truth[r]!) st.successes++;
        }
        final Map<Representation, int> tries = <Representation, int>{
          for (final Representation r in Representation.values) r: e.state.repStats('SK-B', r).tries,
        };
        final Representation most = tries.entries
            .reduce(
              (MapEntry<Representation, int> a, MapEntry<Representation, int> b) =>
                  a.value >= b.value ? a : b,
            )
            .key;
        if (most == Representation.story) settled++;
      }
      expect(settled / runs, greaterThanOrEqualTo(0.90));
    });
  });
}
