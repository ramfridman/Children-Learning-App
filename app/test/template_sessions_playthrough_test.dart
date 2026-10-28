import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/play/trace_session.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

/// QA (M9 B-6): the headless playthrough (`playthrough_test.dart`) answers the drag and placement templates through the
/// controller (`submitPlacement(right: true)`, `submitPlacement(tag: a.wrongTag)`), so it cannot show that the real session
/// can reach the right answer, or that a child's real wrong move produces its tag. This file drives the real session of the
/// seven newest templates over every activity of the pack: the right path by the session's own moves, each wrong move
/// with its tag (the mirror of the number line, coins counted as shekels, the clock's hands, the trace from the other end),
/// and after the help is at its top a wrong move that is not written again.
void main() {
  late PackContent content;
  setUpAll(() async {
    content = await loadStarter();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];

  LessonController startAt(Lesson lesson, int index) {
    final LessonController c = LessonController(
      content: content,
      lesson: lesson,
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async => written.add(r),
    );
    for (int i = 0; i < index; i++) {
      c.next();
    }
    return c;
  }

  /// Every place in a lesson where an activity of type [T] is played (an activity in two lessons is played twice).
  List<(Lesson, int, T)> every<T extends Activity>() => <(Lesson, int, T)>[
    for (final Lesson l in content.lessons.values)
      for (int i = 0; i < l.itemIds.length; i++)
        if (content.activities[l.itemIds[i]] is T) (l, i, content.activities[l.itemIds[i]]! as T),
  ];

  List<AttemptRecord> of(String id) => written.where((AttemptRecord r) => r.activityId == id).toList();

  Future<void> pause(WidgetTester t) =>
      t.pump(TemplateSession.notYetPause + const Duration(milliseconds: 150));

  /// Plays [play] on a fresh controller and session, and gives back what was written for the activity.
  Future<List<AttemptRecord>> run<S extends TemplateSession>(
    WidgetTester t,
    Lesson l,
    int i,
    S Function(LessonController c) make,
    Future<void> Function(S s, LessonController c) play,
  ) async {
    written.clear();
    final LessonController c = startAt(l, i);
    final S s = make(c);
    final String id = c.current.id;
    await play(s, c);
    final List<AttemptRecord> out = of(id);
    // After a right answer the session itself moves the lesson on, once the praise has been said: never a dead end.
    await t.pump(TemplateSession.praisePause + const Duration(milliseconds: 200));
    if (out.isNotEmpty && out.last.result == 'correct') {
      expect(c.finished || c.index == i + 1, isTrue, reason: '$id: the lesson moves on after the praise');
    }
    s.dispose();
    await t.pump(const Duration(seconds: 3));
    return out;
  }

  /// Three wrong moves, then one more while guided: the last is not written; then the right move ends the activity.
  Future<void> guidedCheck<S extends TemplateSession>(
    WidgetTester t,
    Lesson l,
    int i,
    S Function(LessonController c) make,
    Future<void> Function(S s) wrong,
    Future<void> Function(S s) right,
  ) async {
    written.clear();
    final LessonController c = startAt(l, i);
    final S s = make(c);
    final String id = c.current.id;
    for (int k = 0; k < c.current.maxAttempts; k++) {
      await wrong(s);
      await pause(t);
    }
    expect(c.guided, isTrue, reason: '$id: guided after ${c.current.maxAttempts} mistakes');
    final int before = of(id).length;
    await wrong(s);
    await pause(t);
    expect(of(id).length, before, reason: '$id: a wrong move while guided is not written again');
    await right(s);
    expect(of(id).last.result, 'correct', reason: '$id: a guided child can still finish');
    s.dispose();
    await t.pump(const Duration(seconds: 3));
  }

  void expectOneRight(List<AttemptRecord> rs, String id) {
    expect(rs.where((AttemptRecord r) => r.result == 'correct').length, 1, reason: '$id: one right answer');
    expect(
      rs.where((AttemptRecord r) => r.result == 'incorrect'),
      isEmpty,
      reason: '$id: no mistake on the way',
    );
  }

  test(
    'M9 §5 criterion 1: the skill graph has no cycle (the validator refuses only a skill that needs itself)',
    () {
      final Map<String, int> state = <String, int>{}; // 1 on the path being walked, 2 done
      List<String>? walk(String id, List<String> path) {
        if (state[id] == 2) return null;
        if (state[id] == 1) return <String>[...path, id];
        state[id] = 1;
        for (final String p in content.skills[id]?.prerequisites.keys ?? const <String>[]) {
          final List<String>? loop = walk(p, <String>[...path, id]);
          if (loop != null) return loop;
        }
        state[id] = 2;
        return null;
      }

      for (final String id in content.skills.keys) {
        final List<String>? loop = walk(id, const <String>[]);
        expect(loop, isNull, reason: 'a cycle of prerequisites: ${loop?.join(' -> ')}');
      }
    },
  );

  testWidgets('number line: the right tick, the mirror with its own tag, another tick, and guided', (
    WidgetTester t,
  ) async {
    final List<(Lesson, int, NumberLineActivity)> all = every<NumberLineActivity>();
    expect(all, isNotEmpty);
    for (final (Lesson l, int i, NumberLineActivity a) in all) {
      expect(a.target, inInclusiveRange(a.from, a.to), reason: a.id);
      expectOneRight(
        await run(
          t,
          l,
          i,
          (LessonController c) => NumberLineSession(c, a),
          (NumberLineSession s, _) => s.choose(a.target),
        ),
        a.id,
      );
      final int mirror = a.from + a.to - a.target;
      if (a.mirrorTag != null && mirror != a.target) {
        final List<AttemptRecord> rs = await run(
          t,
          l,
          i,
          (LessonController c) => NumberLineSession(c, a),
          (NumberLineSession s, _) => s.choose(mirror),
        );
        expect(rs.single.misconceptionTag, a.mirrorTag, reason: '${a.id}: the mirror tick');
      }
      final int other = <int>[for (int n = a.from; n <= a.to; n++) n]
          .firstWhere((int n) => n != a.target && n != mirror);
      final List<AttemptRecord> rs = await run(
        t,
        l,
        i,
        (LessonController c) => NumberLineSession(c, a),
        (NumberLineSession s, _) => s.choose(other),
      );
      expect(rs.single.result, 'incorrect', reason: a.id);
      expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      await guidedCheck(
        t,
        l,
        i,
        (LessonController c) => NumberLineSession(c, a),
        (NumberLineSession s) => s.choose(other),
        (NumberLineSession s) => s.choose(a.target),
      );
    }
  });

  testWidgets('balance: compare by its tiles, balance by adding blocks, and guided', (WidgetTester t) async {
    final List<(Lesson, int, BalanceActivity)> all = every<BalanceActivity>();
    expect(all, isNotEmpty);
    for (final (Lesson l, int i, BalanceActivity a) in all) {
      if (a.weigh) {
        final int need = int.parse(a.result);
        expect(need, inInclusiveRange(1, 12), reason: '${a.id}: the pan draws at most 12 blocks');
        expectOneRight(
          await run(t, l, i, (LessonController c) => BalanceSession(c, a), (BalanceSession s, _) async {
            for (int k = 0; k < need; k++) {
              await s.addBlock();
            }
          }),
          a.id,
        );
        continue;
      }
      expect(<String>['left', 'same', 'right'], contains(a.result), reason: a.id);
      expectOneRight(
        await run(
          t,
          l,
          i,
          (LessonController c) => BalanceSession(c, a),
          (BalanceSession s, _) => s.choose(a.result),
        ),
        a.id,
      );
      final String other = <String>['left', 'same', 'right'].firstWhere((String w) => w != a.result);
      final List<AttemptRecord> rs = await run(
        t,
        l,
        i,
        (LessonController c) => BalanceSession(c, a),
        (BalanceSession s, _) => s.choose(other),
      );
      expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      await guidedCheck(
        t,
        l,
        i,
        (LessonController c) => BalanceSession(c, a),
        (BalanceSession s) => s.choose(other),
        (BalanceSession s) => s.choose(a.result),
      );
    }
  });

  testWidgets('spot the mistake: the mistake, another cell, and guided', (WidgetTester t) async {
    final List<(Lesson, int, SpotErrorActivity)> all = every<SpotErrorActivity>();
    expect(all, isNotEmpty);
    for (final (Lesson l, int i, SpotErrorActivity a) in all) {
      expect(a.wrong, inInclusiveRange(0, a.cells.length - 1), reason: a.id);
      expectOneRight(
        await run(
          t,
          l,
          i,
          (LessonController c) => SpotErrorSession(c, a),
          (SpotErrorSession s, _) => s.choose(a.wrong),
        ),
        a.id,
      );
      final int other = a.wrong == 0 ? 1 : 0;
      final List<AttemptRecord> rs = await run(
        t,
        l,
        i,
        (LessonController c) => SpotErrorSession(c, a),
        (SpotErrorSession s, _) => s.choose(other),
      );
      expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      await guidedCheck(
        t,
        l,
        i,
        (LessonController c) => SpotErrorSession(c, a),
        (SpotErrorSession s) => s.choose(other),
        (SpotErrorSession s) => s.choose(a.wrong),
      );
    }
  });

  testWidgets('matching pairs: every pair by touch, a wrong pair, and guided', (WidgetTester t) async {
    final List<(Lesson, int, MatchPairsActivity)> all = every<MatchPairsActivity>();
    expect(all, isNotEmpty);
    for (final (Lesson l, int i, MatchPairsActivity a) in all) {
      expect(a.pairs.length, a.left.length, reason: a.id);
      Future<void> allPairs(MatchPairsSession s) async {
        for (final MapEntry<String, String> e in a.pairs.entries) {
          await s.tap(e.key, top: true);
          await s.tap(e.value, top: false);
        }
      }

      expectOneRight(
        await run(
          t,
          l,
          i,
          (LessonController c) => MatchPairsSession(c, a),
          (MatchPairsSession s, _) => allPairs(s),
        ),
        a.id,
      );
      final String left = a.pairs.keys.first;
      final String wrongRight = a.pairs.values.firstWhere((String r) => r != a.pairs[left]);
      Future<void> wrong(MatchPairsSession s) async {
        await s.tap(left, top: true);
        await s.tap(wrongRight, top: false);
      }

      final List<AttemptRecord> rs = await run(
        t,
        l,
        i,
        (LessonController c) => MatchPairsSession(c, a),
        (MatchPairsSession s, _) => wrong(s),
      );
      expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      await guidedCheck(t, l, i, (LessonController c) => MatchPairsSession(c, a), wrong, allPairs);
    }
  });

  testWidgets('shop: the purse can pay the price, coins counted as shekels carry their tag, and guided', (
    WidgetTester t,
  ) async {
    final List<(Lesson, int, ShopPayActivity)> all = every<ShopPayActivity>();
    expect(all, isNotEmpty);
    for (final (Lesson l, int i, ShopPayActivity a) in all) {
      final LessonController probe = startAt(l, i);
      final ShopPaySession p = ShopPaySession(probe, a);
      final Set<String> way = p.solution();
      final List<PurseCoin> purse = List<PurseCoin>.of(p.purse);
      p.dispose();
      expect(way, isNotEmpty, reason: '${a.id}: the purse can pay ${a.price} exactly');
      Future<void> pay(ShopPaySession s, Iterable<String> ids) async {
        for (final String id in ids) {
          s.toggle(id);
        }
        await s.pay();
      }

      expectOneRight(
        await run(
          t,
          l,
          i,
          (LessonController c) => ShopPaySession(c, a),
          (ShopPaySession s, _) => pay(s, way),
        ),
        a.id,
      );
      // Every way to take coins from the purse (at most a few coins, so all of them can be tried).
      final List<List<PurseCoin>> subsets = <List<PurseCoin>>[
        for (int m = 1; m < (1 << purse.length); m++)
          <PurseCoin>[
            for (int k = 0; k < purse.length; k++)
              if (m & (1 << k) != 0) purse[k],
          ],
      ];
      int sum(List<PurseCoin> cs) => cs.fold(0, (int v, PurseCoin c) => v + c.value);
      if (a.countTag != null && a.price % 100 == 0) {
        final List<PurseCoin>? counted = subsets
            .where((List<PurseCoin> cs) => cs.length * 100 == a.price && sum(cs) != a.price)
            .firstOrNull;
        if (counted != null) {
          final List<AttemptRecord> rs = await run(
            t,
            l,
            i,
            (LessonController c) => ShopPaySession(c, a),
            (ShopPaySession s, _) => pay(s, counted.map((PurseCoin c) => c.id)),
          );
          expect(rs.single.misconceptionTag, a.countTag, reason: '${a.id}: as many coins as shekels');
        }
      }
      final List<PurseCoin> off = subsets.firstWhere(
        (List<PurseCoin> cs) => sum(cs) != a.price && cs.length * 100 != a.price,
      );
      Future<void> wrong(ShopPaySession s) => pay(s, off.map((PurseCoin c) => c.id));
      final List<AttemptRecord> rs = await run(
        t,
        l,
        i,
        (LessonController c) => ShopPaySession(c, a),
        (ShopPaySession s, _) => wrong(s),
      );
      expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      await guidedCheck(
        t,
        l,
        i,
        (LessonController c) => ShopPaySession(c, a),
        (ShopPaySession s) async {
          // Guided: the coins of a wrong try stay on the counter; take them back first, as a child would.
          for (final String id in List<String>.of(s.onCounter)) {
            s.toggle(id);
          }
          await wrong(s);
        },
        (ShopPaySession s) async {
          for (final String id in List<String>.of(s.onCounter)) {
            s.toggle(id);
          }
          await pay(s, way);
        },
      );
    }
  });

  testWidgets('clock: the arrows reach the time, twelve carries the hands tag, another hour, and guided', (
    WidgetTester t,
  ) async {
    final List<(Lesson, int, ClockSetActivity)> all = every<ClockSetActivity>();
    expect(all, isNotEmpty);
    Future<void> setTo(ClockSetSession s, int hour, bool half) async {
      for (int k = 0; k < 12 && s.hour != hour; k++) {
        s.next();
      }
      if (s.half != half) s.toggleHalf();
      await s.check();
    }

    for (final (Lesson l, int i, ClockSetActivity a) in all) {
      expect(
        a.startHour != a.hour || a.startHalf != a.half,
        isTrue,
        reason: '${a.id}: the clock does not start at the answer',
      );
      expectOneRight(
        await run(
          t,
          l,
          i,
          (LessonController c) => ClockSetSession(c, a),
          (ClockSetSession s, _) => setTo(s, a.hour, a.half),
        ),
        a.id,
      );
      if (a.handsTag != null && !a.half && a.hour != 12) {
        final List<AttemptRecord> rs = await run(
          t,
          l,
          i,
          (LessonController c) => ClockSetSession(c, a),
          (ClockSetSession s, _) => setTo(s, 12, false),
        );
        expect(rs.single.misconceptionTag, a.handsTag, reason: '${a.id}: twelve o\'clock');
      }
      final int other = <int>[for (int h = 1; h <= 12; h++) h].firstWhere((int h) => h != a.hour && h != 12);
      final List<AttemptRecord> rs = await run(
        t,
        l,
        i,
        (LessonController c) => ClockSetSession(c, a),
        (ClockSetSession s, _) => setTo(s, other, a.half),
      );
      expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      await guidedCheck(
        t,
        l,
        i,
        (LessonController c) => ClockSetSession(c, a),
        (ClockSetSession s) => setTo(s, other, a.half),
        (ClockSetSession s) => setTo(s, a.hour, a.half),
      );
    }
  });

  testWidgets(
    'trace: every path traced from its start is right, and from its end carries the direction tag',
    (WidgetTester t) async {
      final List<(Lesson, int, TraceActivity)> all = every<TraceActivity>();
      expect(all, isNotEmpty);
      Future<void> stroke(TraceSession s, List<Offset> pts) async {
        s.begin(pts.first);
        for (final Offset p in pts.skip(1)) {
          s.extend(p);
        }
        await s.end();
      }

      for (final (Lesson l, int i, TraceActivity a) in all) {
        for (final List<Offset> st in a.strokes) {
          for (final Offset p in st) {
            expect(p.dx, inInclusiveRange(0, 100), reason: a.id);
            expect(p.dy, inInclusiveRange(0, 100), reason: a.id);
          }
        }
        expectOneRight(
          await run(t, l, i, (LessonController c) => TraceSession(c, a), (TraceSession s, _) async {
            for (final List<Offset> st in a.strokes) {
              await stroke(s, st);
            }
          }),
          a.id,
        );
        final List<Offset> first = a.strokes.first;
        final bool open = (first.first - first.last).distance > a.tolerance * 2.2;
        if (a.directionTag != null && open) {
          final List<AttemptRecord> rs = await run(
            t,
            l,
            i,
            (LessonController c) => TraceSession(c, a),
            (TraceSession s, _) => stroke(s, first.reversed.toList()),
          );
          expect(rs.single.misconceptionTag, a.directionTag, reason: '${a.id}: traced from the other end');
        }
        final List<AttemptRecord> rs = await run(
          t,
          l,
          i,
          (LessonController c) => TraceSession(c, a),
          (TraceSession s, _) => stroke(s, const <Offset>[Offset(1, 1), Offset(3, 2)]),
        );
        expect(rs.single.result, 'incorrect', reason: a.id);
        expect(rs.single.misconceptionTag, a.wrongTag ?? '', reason: a.id);
      }
    },
  );
}
