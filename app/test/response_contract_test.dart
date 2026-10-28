import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/response_code.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/play/trace_session.dart';
import 'package:nitznutz/tutor/tutor.dart';

import 'support/fake_tutor.dart';
import 'support/fakes.dart';
import 'support/starter.dart';

/// SEC-1: every answer a template writes is synced to `sync-push`, which takes `attempt.response` only in its pattern and
/// refuses the whole batch for one row outside it. This plays the real session of every template over every activity of the
/// starter pack, with the right moves and every wrong move a child can make, and checks each code against the server's pattern
/// (kept equal to the server through `testvectors/wire-patterns.json`).
void main() {
  late PackContent content;
  setUpAll(() async {
    content = await loadStarter();
  });

  test('the app and both servers take the same patterns (testvectors/wire-patterns.json)', () {
    final Map<String, Object?> v =
        jsonDecode(File('../testvectors/wire-patterns.json').readAsStringSync()) as Map<String, Object?>;
    final Map<String, Object?> fields = v['attempt_fields']! as Map<String, Object?>;
    expect(responsePattern, (fields['response']! as Map<String, Object?>)['pattern']);
    expect(tutorOptionPattern, v['tutor_option']);
    // The examples are what the templates write; the Deno test sends each of them through the real sync-push.
    final Map<String, Object?> examples = v['examples']! as Map<String, Object?>;
    final Map<String, String> built = <String, String>{
      'choice': 'o2',
      'give_n': ResponseCode.count(4),
      'sort': ResponseCode.sortMove('i1', 'b2'),
      'share': ResponseCode.share(const <(String, int)>[('b1', 3), ('b2', 1)]),
      'pattern': ResponseCode.pattern(const <int?>[0, 1, 0, 1, 0, 1, 0, 1]),
      'program': ResponseCode.program(const <String>[
        'up',
        'up',
        'right',
        'right',
        'down',
        'left',
        'left',
        'up',
      ]),
      'shape': ResponseCode.shapeMove(9, 's12'),
      'pairs': ResponseCode.pairs(const <(int, int)>[(0, 4), (1, 3), (2, 2), (3, 1), (4, 0)]),
      'clock': ResponseCode.clock(12, half: true),
      'shop': '1280000',
      'trace': ResponseCode.tracedBackwards,
    };
    expect(built, examples);
    for (final String code in built.values) {
      expect(ResponseCode.fits(code), isTrue, reason: code);
    }
  });

  test('the helper is told a code only when it fits its own pattern, else the fixed word "move"', () {
    final RegExp option = RegExp(tutorOptionPattern);
    for (final String code in <String>['o2', 'n=4', 'i1-b2', 't0-b1', 'p3-s1', 'uurd', '7', 'left']) {
      expect(ResponseCode.tutorOption(code), code);
    }
    for (final String code in <String>['', '3.30', 'b1=3.b2=1', 'Built', 't0-b2.t1-b0.t2-b1']) {
      expect(ResponseCode.tutorOption(code), ResponseCode.move, reason: code);
    }
    expect(option.hasMatch(ResponseCode.move), isTrue);
  });

  final List<AttemptRecord> written = <AttemptRecord>[];
  final Set<String> templatesSeen = <String>{};

  /// The first place each activity is played: the code it writes does not depend on the lesson.
  Map<String, (Lesson, int)> places() {
    final Map<String, (Lesson, int)> at = <String, (Lesson, int)>{};
    for (final Lesson l in content.lessons.values) {
      for (int i = 0; i < l.itemIds.length; i++) {
        at.putIfAbsent(l.itemIds[i], () => (l, i));
      }
    }
    return at;
  }

  List<(Lesson, int, T)> every<T extends Activity>() => <(Lesson, int, T)>[
    for (final MapEntry<String, (Lesson, int)> e in places().entries)
      if (content.activities[e.key] is T) (e.value.$1, e.value.$2, content.activities[e.key]! as T),
  ];

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

  /// One move (or a few) on a fresh activity, so that each wrong move is written (none is swallowed by the guided state).
  Future<void> move<S extends TemplateSession>(
    WidgetTester t,
    (Lesson, int) at,
    S Function(LessonController c) make,
    Future<void> Function(S s) play, {
    Duration settle = const Duration(milliseconds: 10),
  }) async {
    final S s = make(startAt(at.$1, at.$2));
    await play(s);
    await t.pump(settle);
    s.dispose();
  }

  /// Every code written so far fits the server's pattern; at least [atLeast] were written.
  void expectAllFit(String template, {int atLeast = 1}) {
    final List<AttemptRecord> mine = written.where((AttemptRecord r) => r.template == template).toList();
    expect(mine.length, greaterThanOrEqualTo(atLeast), reason: '$template: answers were written');
    final List<String> bad = <String>[
      for (final AttemptRecord r in mine)
        if (!ResponseCode.fits(r.response)) '${r.activityId}: "${r.response}"',
    ];
    expect(bad, isEmpty, reason: '$template writes codes sync-push refuses:\n${bad.take(20).join('\n')}');
    expect(
      mine.where((AttemptRecord r) => r.result == 'correct'),
      isNotEmpty,
      reason: '$template: a right answer',
    );
    expect(
      mine.where((AttemptRecord r) => r.result == 'incorrect'),
      isNotEmpty,
      reason: '$template: a wrong one',
    );
    templatesSeen.add(template);
    written.removeWhere((AttemptRecord r) => r.template == template);
  }

  test('the choice templates write their option ids, and give N the number given', () async {
    for (final (Lesson l, int i, Activity a) in every<Activity>()) {
      final List<String> options = switch (a) {
        CountTapActivity() => <String>[for (final ChoiceOption o in a.options) o.id],
        TapAnswerActivity() => <String>[for (final ChoiceOption o in a.options) o.id],
        FlashActivity() => <String>[for (final ChoiceOption o in a.options) o.id],
        _ => const <String>[],
      };
      for (final String o in options) {
        await startAt(l, i).chooseOption(o);
      }
      if (a is GiveNActivity) {
        for (int k = 1; k <= a.sourceCount; k++) {
          await startAt(l, i).giveN(k);
        }
      }
    }
    for (final String t in <String>['count_tap', 'tap_answer', 'flash', 'give_n']) {
      expectAllFit(t);
    }
  });

  testWidgets('sort and share: every item in every wrong bin, an unequal share, and the right sort', (
    WidgetTester t,
  ) async {
    for (final (Lesson l, int i, SortDragActivity a) in every<SortDragActivity>()) {
      SortDragSession make(LessonController c) => SortDragSession(c, a);
      if (a.share) {
        await move(t, (l, i), make, (SortDragSession s) async {
          for (final SortItem it in a.items) {
            await s.drop(it.id, a.bins.first.id);
          }
        });
        await move(t, (l, i), make, (SortDragSession s) async {
          for (final (int k, SortItem it) in a.items.indexed) {
            await s.drop(it.id, a.bins[k % a.bins.length].id);
          }
        });
        continue;
      }
      for (final SortItem it in a.items) {
        for (final SortBin b in a.bins.where((SortBin b) => b.id != it.bin)) {
          await move(t, (l, i), make, (SortDragSession s) => s.drop(it.id, b.id));
        }
      }
      await move(t, (l, i), make, (SortDragSession s) async {
        for (final SortItem it in a.items) {
          await s.drop(it.id, it.bin!);
        }
      });
    }
    expectAllFit('sort_drag');
  });

  testWidgets(
    'build a pattern: one wrong picture in each place, all the last picture, and the right pattern',
    (WidgetTester t) async {
      for (final (Lesson l, int i, BuildPatternActivity a) in every<BuildPatternActivity>()) {
        BuildPatternSession make(LessonController c) => BuildPatternSession(c, a);
        Future<void> fill(BuildPatternSession s, List<String> pictures) async {
          for (final (int k, String p) in pictures.indexed) {
            await s.place(p, at: k);
          }
        }

        for (int k = 0; k < a.slots; k++) {
          final String other = a.palette.firstWhere((String p) => p != a.sequence[k]);
          await move(
            t,
            (l, i),
            make,
            (BuildPatternSession s) => fill(s, <String>[...a.sequence]..[k] = other),
          );
        }
        await move(
          t,
          (l, i),
          make,
          (BuildPatternSession s) => fill(s, List<String>.filled(a.slots, a.palette.last)),
        );
        await move(t, (l, i), make, (BuildPatternSession s) => fill(s, a.sequence));
      }
      expectAllFit('build_pattern');
    },
  );

  testWidgets('robot: the longest wrong programs, the right one, and the direct robot reaching its flag', (
    WidgetTester t,
  ) async {
    for (final (Lesson l, int i, RobotPathActivity a) in every<RobotPathActivity>()) {
      RobotPathSession make(LessonController c) => RobotPathSession(c, a);
      final Duration walk = Duration(milliseconds: 450 * (a.maxSteps + 2));
      Future<void> run(RobotPathSession s, List<String> steps) async {
        for (final String d in steps) {
          await s.arrow(d);
        }
        await s.go();
      }

      if (!a.plan) {
        await move(t, (l, i), make, (RobotPathSession s) async {
          final (int, int) g = a.goalAt;
          while (s.pos != g) {
            await s.arrow(
              s.pos.$1 != g.$1 ? (s.pos.$1 < g.$1 ? 'right' : 'left') : (s.pos.$2 < g.$2 ? 'down' : 'up'),
            );
          }
        });
        continue;
      }
      final List<List<String>> wrong = <List<String>>[
        for (final String d in <String>['up', 'down', 'left', 'right']) List<String>.filled(a.maxSteps, d),
        <String>[...a.solution.take(a.solution.length - 1)],
        <String>[...a.solution, a.solution.last],
      ].where((List<String> p) => p.isNotEmpty && p.length <= a.maxSteps).toList();
      for (final List<String> p in wrong) {
        await move(t, (l, i), make, (RobotPathSession s) => run(s, p), settle: walk);
      }
      await move(t, (l, i), make, (RobotPathSession s) => run(s, a.solution), settle: walk);
    }
    expectAllFit('robot_path');
  });

  testWidgets('shape builder: every piece in every place it does not fit, and the whole picture', (
    WidgetTester t,
  ) async {
    for (final (Lesson l, int i, ShapeBuilderActivity a) in every<ShapeBuilderActivity>()) {
      ShapeBuilderSession make(LessonController c) => ShapeBuilderSession(c, a);
      final List<String> pieces = a.pieces;
      for (int p = 0; p < pieces.length; p++) {
        for (final ShapeSlot slot in a.slots.where((ShapeSlot s) => s.sprite != pieces[p])) {
          await move(t, (l, i), make, (ShapeBuilderSession s) => s.drop(p, slot.id));
        }
      }
      await move(t, (l, i), make, (ShapeBuilderSession s) async {
        for (final ShapeSlot slot in a.slots) {
          final int p = <int>[
            for (int k = 0; k < pieces.length; k++)
              if (pieces[k] == slot.sprite && !s.isUsed(k)) k,
          ].first;
          await s.drop(p, slot.id);
        }
      });
    }
    expectAllFit('shape_builder');
  });

  testWidgets('match pairs: every wrong pair, and all the pairs', (WidgetTester t) async {
    for (final (Lesson l, int i, MatchPairsActivity a) in every<MatchPairsActivity>()) {
      MatchPairsSession make(LessonController c) => MatchPairsSession(c, a);
      for (final MatchFace top in a.left) {
        for (final MatchFace bottom in a.right.where((MatchFace f) => f.id != a.pairs[top.id])) {
          await move(t, (l, i), make, (MatchPairsSession s) async {
            await s.tap(top.id, top: true);
            await s.tap(bottom.id, top: false);
          });
        }
      }
      await move(t, (l, i), make, (MatchPairsSession s) async {
        for (final MapEntry<String, String> e in a.pairs.entries) {
          await s.tap(e.key, top: true);
          await s.tap(e.value, top: false);
        }
      });
    }
    expectAllFit('match_pairs');
  });

  testWidgets('number line, balance and spot the mistake: every answer there is', (WidgetTester t) async {
    for (final (Lesson l, int i, NumberLineActivity a) in every<NumberLineActivity>()) {
      for (int n = a.from; n <= a.to; n++) {
        await move(
          t,
          (l, i),
          (LessonController c) => NumberLineSession(c, a),
          (NumberLineSession s) => s.choose(n),
        );
      }
    }
    for (final (Lesson l, int i, BalanceActivity a) in every<BalanceActivity>()) {
      BalanceSession make(LessonController c) => BalanceSession(c, a);
      if (a.weigh) {
        await move(t, (l, i), make, (BalanceSession s) async {
          for (int k = 0; k < int.parse(a.result); k++) {
            await s.addBlock();
          }
        });
        continue;
      }
      for (final String w in <String>['left', 'same', 'right']) {
        await move(t, (l, i), make, (BalanceSession s) => s.choose(w));
      }
    }
    for (final (Lesson l, int i, SpotErrorActivity a) in every<SpotErrorActivity>()) {
      for (int k = 0; k < a.cells.length; k++) {
        await move(
          t,
          (l, i),
          (LessonController c) => SpotErrorSession(c, a),
          (SpotErrorSession s) => s.choose(k),
        );
      }
    }
    expectAllFit('number_line');
    expectAllFit('balance');
    expectAllFit('spot_error');
  });

  testWidgets('shop: each coin alone, the whole purse, and the way to pay', (WidgetTester t) async {
    for (final (Lesson l, int i, ShopPayActivity a) in every<ShopPayActivity>()) {
      ShopPaySession make(LessonController c) => ShopPaySession(c, a);
      Future<void> pay(ShopPaySession s, Iterable<String> ids) async {
        for (final String id in ids) {
          s.toggle(id);
        }
        await s.pay();
      }

      final ShopPaySession probe = make(startAt(l, i));
      final List<String> all = <String>[for (final PurseCoin c in probe.purse) c.id];
      final Set<String> way = probe.solution();
      probe.dispose();
      for (final String id in all) {
        await move(t, (l, i), make, (ShopPaySession s) => pay(s, <String>[id]));
      }
      await move(t, (l, i), make, (ShopPaySession s) => pay(s, all));
      await move(t, (l, i), make, (ShopPaySession s) => pay(s, way));
    }
    expectAllFit('shop_pay');
  });

  testWidgets('clock: every hour, whole and half where the activity has halves', (WidgetTester t) async {
    for (final (Lesson l, int i, ClockSetActivity a) in every<ClockSetActivity>()) {
      for (int h = 1; h <= 12; h++) {
        for (final bool half in <bool>[false, if (a.half || a.startHalf) true]) {
          await move(t, (l, i), (LessonController c) => ClockSetSession(c, a), (ClockSetSession s) async {
            for (int k = 0; k < 12 && s.hour != h; k++) {
              s.next();
            }
            if (s.half != half) s.toggleHalf();
            await s.check();
          });
        }
      }
    }
    expectAllFit('clock_set');
  });

  testWidgets('trace: every path from its start, from its end, and off the path', (WidgetTester t) async {
    for (final (Lesson l, int i, TraceActivity a) in every<TraceActivity>()) {
      TraceSession make(LessonController c) => TraceSession(c, a);
      Future<void> stroke(TraceSession s, List<Offset> pts) async {
        s.begin(pts.first);
        for (final Offset p in pts.skip(1)) {
          s.extend(p);
        }
        await s.end();
      }

      await move(t, (l, i), make, (TraceSession s) async {
        for (final List<Offset> st in a.strokes) {
          await stroke(s, st);
        }
      });
      await move(t, (l, i), make, (TraceSession s) => stroke(s, a.strokes.first.reversed.toList()));
      await move(t, (l, i), make, (TraceSession s) => stroke(s, const <Offset>[Offset(1, 1), Offset(3, 2)]));
    }
    expectAllFit('trace');
  });

  testWidgets(
    'the helper is asked with options that tutor-turn takes, after two wrong moves of each template',
    (WidgetTester t) async {
      final RegExp option = RegExp(tutorOptionPattern);
      final List<String> sent = <String>[];
      Future<void> twice<S extends TemplateSession>(
        Activity a,
        S Function(LessonController c) make,
        Future<void> Function(S s) wrong,
      ) async {
        final (Lesson l, int i) = places()[a.id]!;
        // Nothing made ahead (the service says its ahead-of-time cap is reached), so each mistake is asked for live.
        final FakeTutorClient client = FakeTutorClient()..rule = 'prefetch_cap';
        final LessonController c = startAt(l, i)
          ..attachTutor(
            TutorSession(client: client),
            const TutorContext(
              packId: 'starter',
              packVersion: '0.8.0',
              characterId: 'nitzi',
              band: 'B',
              addressForm: 'f',
              childRef: 'child-ref-0001',
              sessionRef: 'session-ref-0001',
            ),
          );
        final S s = make(c);
        for (int k = 0; k < 2; k++) {
          await wrong(s);
          await t.pump(TemplateSession.notYetPause + const Duration(milliseconds: 300));
        }
        s.dispose();
        final List<TutorAsk> live = client.asked.where((TutorAsk q) => !q.prefetch).toList();
        expect(live, isNotEmpty, reason: '${a.id}: the helper was asked after the second mistake');
        for (final TutorAsk q in live) {
          for (final Object? at in q.toJson()['attempts']! as List<Object?>) {
            sent.add((at! as Map<String, Object?>)['option']! as String);
          }
        }
      }

      final SortDragActivity sort = every<SortDragActivity>().firstWhere((x) => !x.$3.share).$3;
      final SortItem item = sort.items.first;
      await twice(
        sort,
        (LessonController c) => SortDragSession(c, sort),
        (SortDragSession s) => s.drop(item.id, sort.bins.firstWhere((SortBin b) => b.id != item.bin).id),
      );
      final ClockSetActivity clock = every<ClockSetActivity>().first.$3;
      await twice(clock, (LessonController c) => ClockSetSession(c, clock), (ClockSetSession s) async {
        s.next();
        if (s.hour == clock.hour) s.next();
        await s.check();
      });
      final RobotPathActivity robot = every<RobotPathActivity>().firstWhere((x) => x.$3.plan).$3;
      await twice(robot, (LessonController c) => RobotPathSession(c, robot), (RobotPathSession s) async {
        for (int k = 0; k < robot.maxSteps; k++) {
          await s.arrow('up');
        }
        await s.go();
        await t.pump(Duration(milliseconds: 450 * (robot.maxSteps + 2)));
      });
      expect(sent, isNotEmpty);
      for (final String o in sent) {
        expect(option.hasMatch(o), isTrue, reason: '"$o" would make tutor-turn refuse the call');
      }
      expect(
        sent,
        contains(ResponseCode.sortMove(item.id, sort.bins.firstWhere((SortBin b) => b.id != item.bin).id)),
      );
      expect(sent, contains(ResponseCode.move), reason: 'a clock time does not fit, and is told as a move');
    },
  );

  test('every template of the pack was played above', () {
    final Set<String> inPack = <String>{for (final Activity a in content.activities.values) a.template};
    expect(templatesSeen, inPack);
  });
}
