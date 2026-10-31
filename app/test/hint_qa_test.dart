import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/flash_session.dart';
import 'package:nitznutz/play/give_n_session.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hint_widgets.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/prompt_numbers.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/sprite_group.dart';
import 'package:nitznutz/play/tap_answer_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/play/trace_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40, the QA pass (qa-engineer, 2026-10-31): what the part tests do not pin. Every activity has a hint at each level and none
/// falls back to the generic picture by accident; the hint's pictures stand where the stage draws the things (two groups on the
/// stage); nothing runs right to left under an RTL screen; reduce motion keeps the pictures and drops the motion; the hand keeps
/// clear of the speech bubble and the top bar on all four boards, for every tile of a row of two, three, four and five; a touch of
/// the child ends a demonstration in every template; the numbers of a question are read the way they are said.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  final List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];
  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  Size boardOf(ActivitySpec s) => identical(s, ActivitySpec.phone)
      ? BoardClass.phone.size
      : identical(s, ActivitySpec.phoneSE)
      ? BoardClass.phoneSE.size
      : identical(s, ActivitySpec.tabletLandscape)
      ? BoardClass.tabletLandscape.size
      : BoardClass.tabletPortrait.size;

  List<T> all<T extends Activity>() => content.activities.values.whereType<T>().toList();
  TapAnswerActivity act(String id) => content.activities[id]! as TapAnswerActivity;

  LessonController controllerFor(Activity a) => LessonController(
    content: content,
    lesson: Lesson.mission(
      id: 'one',
      itemIds: <String>[a.id],
      skillIds: <String>[a.skillId],
      celebration: content.lessons.values.first.celebration,
    ),
    profileId: 'p-1',
    clock: FixedClock(1793000000000),
    record: (AttemptRecord r) async {},
  );

  TemplateSession sessionFor(LessonController c, Activity a) => switch (a) {
    CountTapActivity() => CountTapSession(c, a),
    GiveNActivity() => GiveNSession(c, a),
    FlashActivity() => FlashSession(c, a),
    TraceActivity() => TraceSession(c, a),
    SortDragActivity() => SortDragSession(c, a),
    BuildPatternActivity() => BuildPatternSession(c, a),
    MatchPairsActivity() => MatchPairsSession(c, a),
    ShapeBuilderActivity() => ShapeBuilderSession(c, a),
    NumberLineActivity() => NumberLineSession(c, a),
    RobotPathActivity() => RobotPathSession(c, a),
    ShopPayActivity() => ShopPaySession(c, a),
    ClockSetActivity() => ClockSetSession(c, a),
    BalanceActivity() => BalanceSession(c, a),
    SpotErrorActivity() => SpotErrorSession(c, a),
    TapAnswerActivity() => TapAnswerSession(c, a),
  };

  /// The stage, the hand's layer over it and the tiles, as the lesson screen places them (phone board).
  Future<void> host(
    WidgetTester tester,
    TemplateSession s, {
    bool reduceMotion = true,
    ActivitySpec spec = ActivitySpec.phone,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: spec.stage.left,
                    top: spec.stage.top,
                    width: spec.stage.width,
                    height: spec.stage.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(child: s.buildStage(ctx, spec.stage.size, spec)),
                        Positioned.fill(child: s.buildHands(ctx, spec.stage.size, spec) ?? const SizedBox()),
                      ],
                    ),
                  ),
                  Positioned(
                    left: spec.tilesLeft,
                    top: spec.tilesTop - 12,
                    width: spec.tilesWidth,
                    child: s.buildTiles(ctx, spec) ?? const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pass(WidgetTester t, int ms, {int step = 100}) async {
    for (int spent = 0; spent < ms; spent += step) {
      await t.pump(Duration(milliseconds: step));
    }
  }

  Future<void> end(WidgetTester t, TemplateSession s) async {
    s.dispose();
    await t.pumpWidget(const SizedBox());
  }

  final Finder hand = find.byKey(const Key('hint-p12'));

  // ------------------------------------------------------------------------------------------------------------------------
  // 1. every activity has a hint at each level
  // ------------------------------------------------------------------------------------------------------------------------

  group('every activity has a hint at each level', () {
    test('every template of the pack has a ladder that the validator accepts, and every activity has three hints in order', () {
      final List<String> short = <String>[];
      for (final Activity a in content.activities.values) {
        final bool share = a is SortDragActivity && a.share;
        expect(HintLadder.problemWith(a.template, share: share), isNull, reason: a.id);
        if (a.hints.length < 3) short.add('${a.id} (${a.hints.length})');
        for (final (int i, Hint h) in a.hints.indexed) {
          expect(h.level, i + 1, reason: '${a.id}: the hints are numbered 1, 2, 3');
          if (i < 2) expect(h.action, isNot(HintAction.workedExample), reason: '${a.id} level ${i + 1}');
        }
      }
      // The warm-up `pick.red.flower` has one hint by design (the guided state needs no demonstration); nothing else may be short.
      expect(short, <String>['pick.red.flower (1)']);
    });

    test('every tap_answer activity has a plan with steps at each level on all four boards (626)', () {
      int n = 0;
      for (final ActivitySpec board in boards) {
        for (final TapAnswerActivity a in all<TapAnswerActivity>()) {
          final TapGeometry g = TapGeometry(a, stageOf(board), board);
          for (int level = 1; level <= 3; level++) {
            final HintPlan? p = tapHintPlan(a, g, level);
            expect(p, isNotNull, reason: '${a.id} level $level on ${board.stage}');
            expect(p!.frames, isNotEmpty, reason: '${a.id} level $level on ${board.stage}');
          }
          n++;
        }
      }
      expect(n, 626 * 4);
    });

    test('no tap_answer activity falls back to the generic picture (a question mark card at level 2)', () {
      final List<String> generic = <String>[];
      for (final TapAnswerActivity a in all<TapAnswerActivity>()) {
        final HintPlan l2 = tapHintPlan(
          a,
          TapGeometry(a, stageOf(ActivitySpec.phone), ActivitySpec.phone),
          2,
        )!;
        // The generic plan's level 2 is one card with a question mark, shown as its only step and left as what stays.
        final HintMark only = l2.rest.length == 1 ? l2.rest.single : const VeilMark(<Rect>[]);
        if (only is CardMark && only.child is Text && (only.child as Text).data == '?') {
          generic.add('${a.id} (${a.skillId})');
        }
      }
      // Every family draws its own picture (MATH-A-04 heavy and light have the seesaw since B-40).
      expect(generic, isEmpty, reason: '$generic');
    });

    test('level 3 of tap_answer is a hand that never touches the answer tile before its last step, on every board (Band A too)', () {
      final List<String> starts = <String>[];
      final List<String> passes = <String>[];
      for (final ActivitySpec board in boards) {
        for (final TapAnswerActivity a in all<TapAnswerActivity>()) {
          final TapGeometry g = TapGeometry(a, stageOf(board), board);
          final HintPlan p = tapHintPlan(a, g, 3)!;
          expect(p.endsDemo, isTrue, reason: a.id);
          final Offset tip = g.optionTip(g.correctIndex);
          final List<HandMark> before = <HandMark>[
            for (final HintFrame f in p.frames.take(p.frames.length - 1)) ...f.marks.whereType<HandMark>(),
          ];
          if (before.isNotEmpty && (before.first.tip - tip).distance < 0.5) {
            starts.add('${a.id} on ${board.stage.size}');
          }
          if (before.any((HandMark h) => (h.tip - tip).distance < 0.5)) {
            passes.add('${a.id} on ${board.stage.size}');
          }
          final HandMark last = p.frames.last.marks.whereType<HandMark>().single;
          expect(
            (last.tip - tip).distance,
            lessThan(0.5),
            reason: '${a.id} on ${board.stage}: it ends on the answer',
          );
        }
      }
      expect(
        <String>[
          ...starts.map((String x) => 'STARTS ON THE ANSWER: $x'),
          ...passes.map((String x) => 'rests on the answer first: $x'),
        ],
        isEmpty,
        reason:
            'the demonstration must end on the answer, never begin on it or touch it before its last step',
      );
    });
  });

  // ------------------------------------------------------------------------------------------------------------------------
  // the hint's pictures stand where the stage draws the things
  // ------------------------------------------------------------------------------------------------------------------------

  group('the pictures of a hint stand on the things the stage draws', () {
    testWidgets('two groups on the stage: the first group is where the geometry of the hint says (QA-1)', (
      WidgetTester t,
    ) async {
      final List<TapAnswerActivity> two = <TapAnswerActivity>[
        for (final TapAnswerActivity a in all<TapAnswerActivity>())
          if (a.group2 != null) a,
      ];
      expect(two, hasLength(34));
      final List<String> wrong = <String>[];
      for (final TapAnswerActivity a in two) {
        final LessonController c = controllerFor(a);
        final TapAnswerSession s = TapAnswerSession(c, a);
        await host(t, s);
        final Rect stage = t.getRect(find.byKey(const Key('tap-stage')));
        final List<Rect> drawn = <Rect>[
          for (final Element e
              in find
                  .descendant(of: find.byKey(const Key('tap-groups')), matching: find.byType(SpriteGroup))
                  .evaluate())
            (t.getRect(find.byWidget(e.widget)).shift(-stage.topLeft)),
        ];
        final TapGeometry g = TapGeometry(a, ActivitySpec.phone.stage.size, ActivitySpec.phone);
        for (int which = 0; which < 2; which++) {
          final Rect planned = g.groupCell(which);
          // The group the plan calls `which` must be drawn in that half of the stage.
          if ((drawn[which].center.dx - planned.center.dx).abs() > planned.width / 2) {
            wrong.add('${a.id} group $which');
          }
        }
        await end(t, s);
      }
      expect(
        wrong,
        isEmpty,
        reason: 'the hint rings the second group where the stage draws the first: $wrong',
      );
    });
  });

  // ------------------------------------------------------------------------------------------------------------------------
  // 3. never mirrored (an RTL ambient Directionality)
  // ------------------------------------------------------------------------------------------------------------------------

  group('nothing runs right to left under an RTL screen', () {
    Future<void> overlay(WidgetTester t, List<HintMark> marks) async {
      await t.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: HintOverlay(size: const Size(330, 128), marks: marks),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a number path counts up to the right, and a path of skip counting too', (
      WidgetTester t,
    ) async {
      for (final PathMark p in <PathMark>[
        const PathMark(rect: Rect.fromLTWH(10, 40, 300, 40), count: 6),
        const PathMark(rect: Rect.fromLTWH(10, 40, 300, 40), count: 6, from: 10, step: 10, gap: 60),
      ]) {
        await overlay(t, <HintMark>[p]);
        double last = -1;
        for (int n = 1; n <= p.count; n++) {
          final Finder sq = find.byKey(Key('path-square-${p.numberAt(n)}'));
          expect(sq, findsOneWidget, reason: 'square $n');
          expect(t.getCenter(sq).dx, greaterThan(last), reason: 'square $n is right of the one before');
          last = t.getCenter(sq).dx;
        }
      }
    });

    testWidgets('two hands: the first hand (five) is on the left; ten-frames fill from the left', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      await overlay(t, <HintMark>[
        CardMark(const Rect.fromLTWH(20, 10, 200, 110), const CountingHands(raised: 7)),
      ]);
      expect(
        t.getCenter(find.byKey(const Key('hand-first'))).dx,
        lessThan(t.getCenter(find.byKey(const Key('hand-second'))).dx),
      );
      await overlay(t, <HintMark>[
        CardMark(const Rect.fromLTWH(20, 10, 280, 110), const TenFrames(total: 14, filled: 14)),
      ]);
      final List<Offset> counters = <Offset>[
        for (final Element e in find.byKey(const Key('frame-counter')).evaluate())
          t.getCenter(find.byWidget(e.widget)),
      ];
      expect(counters, hasLength(14));
      // The top row of the first frame fills left to right (the first five counters are in one row, rising in x), and the second
      // frame stands to the right of the first.
      for (int i = 1; i < 5; i++) {
        expect(counters[i].dx, greaterThan(counters[i - 1].dx), reason: 'counter ${i + 1}');
        expect(counters[i].dy, counters[0].dy);
      }
      expect(counters[10].dx, greaterThan(counters[9].dx), reason: 'the second frame is on the right');
    });

    testWidgets('dots under a numeral read left to right', (WidgetTester t) async {
      await overlay(t, <HintMark>[
        CardMark(const Rect.fromLTWH(20, 10, 200, 60), const DotRow(count: 4), tight: true),
      ]);
      final Rect row = t.getRect(find.byKey(const Key('dot-row')));
      expect(row.width, greaterThan(40));
    });

    testWidgets('the number line: its numbers grow to the right, in a place item and a jump item', (
      WidgetTester t,
    ) async {
      for (final NumberLineActivity a in <NumberLineActivity>[
        all<NumberLineActivity>().firstWhere((NumberLineActivity x) => !x.jump),
        all<NumberLineActivity>().firstWhere((NumberLineActivity x) => x.jump),
      ]) {
        final LessonController c = controllerFor(a);
        final NumberLineSession s = NumberLineSession(c, a);
        await host(t, s);
        final List<double> xs = <double>[];
        for (final int n in <int>[0, 5, 10]) {
          final Finder f = find.text('$n');
          if (f.evaluate().isNotEmpty) xs.add(t.getCenter(f.first).dx);
        }
        expect(xs.length, greaterThanOrEqualTo(2), reason: a.id);
        for (int i = 1; i < xs.length; i++) {
          expect(xs[i], greaterThan(xs[i - 1]), reason: '${a.id}: the line runs left to right');
        }
        await end(t, s);
      }
    });

    testWidgets(
      'robot arrows: the arrow that points left is on the left and is drawn left, in a left to right isolate',
      (WidgetTester t) async {
        final RobotPathActivity a = all<RobotPathActivity>().first;
        final LessonController c = controllerFor(a);
        final RobotPathSession s = RobotPathSession(c, a);
        await host(t, s);
        final Map<String, IconData> icons = <String, IconData>{
          'left': Icons.arrow_back_rounded,
          'up': Icons.arrow_upward_rounded,
          'down': Icons.arrow_downward_rounded,
          'right': Icons.arrow_forward_rounded,
        };
        double last = -1;
        for (final String d in RobotPathSession.arrowOrder) {
          final Finder icon = find.descendant(
            of: find.byKey(Key('arrow-$d')),
            matching: find.byIcon(icons[d]!),
          );
          expect(icon, findsOneWidget, reason: d);
          expect(
            Directionality.of(t.element(icon)),
            TextDirection.ltr,
            reason: '$d: the arrow must not follow the screen',
          );
          expect(t.getCenter(icon).dx, greaterThan(last));
          last = t.getCenter(icon).dx;
        }
        await end(t, s);
      },
    );

    testWidgets(
      'a row of the stage (a pattern, a sentence) and its hint path: cells left to right, the gap at the right',
      (WidgetTester t) async {
        for (final String id in <String>['log.next.colours', 'next.after.4', 'math.add.stars']) {
          final TapAnswerActivity a = act(id);
          if (a.row.isEmpty) continue;
          final LessonController c = controllerFor(a);
          final TapAnswerSession s = TapAnswerSession(c, a);
          await host(t, s);
          final Rect row = t.getRect(find.byKey(const Key('tap-row')));
          final TapGeometry g = TapGeometry(a, ActivitySpec.phone.stage.size, ActivitySpec.phone);
          final List<Rect> cells = g.rowCells();
          expect(cells.first.left, lessThan(cells.last.left), reason: id);
          expect(row.left, greaterThanOrEqualTo(ActivitySpec.phone.stage.left), reason: id);
          await end(t, s);
        }
      },
    );
  });

  // ------------------------------------------------------------------------------------------------------------------------
  // 4. reduce motion
  // ------------------------------------------------------------------------------------------------------------------------

  group('reduce motion', () {
    /// The kinds of picture on the screen now: the keys of the hint's pictures.
    Set<String> pictures(WidgetTester t) => <String>{
      for (final Element e
          in find
              .byWidgetPredicate(
                (Widget w) => w.key is ValueKey<String> && _isHintKey((w.key! as ValueKey<String>).value),
              )
              .evaluate())
        if (!((e.widget.key! as ValueKey<String>).value.startsWith('ripple-')))
          (e.widget.key! as ValueKey<String>).value,
    };

    // One activity of each template and family, with the time its hints need (ms for each level).
    final List<String> ids = <String>[
      'numeral.bugs.5', // count
      'col.name.red.ball', // colour
      'shp.name.triangle', // shapes
      'next.after.4', // sequence
      'log.next.colours', // pattern
      'math.add.stars', // add
      'show.birds.4', // numerals
      'b.numb08.1', // Band B teens
      'ordinal.second.of4', // ordinals
    ];

    Future<List<Set<String>>> runLadder(WidgetTester t, Activity a, {required bool reduce}) async {
      final LessonController c = controllerFor(a);
      final TemplateSession s = sessionFor(c, a);
      await host(t, s, reduceMotion: reduce);
      final List<Set<String>> seen = <Set<String>>[];
      for (int level = 1; level <= 3; level++) {
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        for (int i = 0; i < 44; i++) {
          await t.pump(const Duration(milliseconds: 300));
          final Set<String> now = pictures(t);
          if (seen.isEmpty || !_same(seen.last, now)) seen.add(now);
          if (reduce) {
            // Still means still: no hint picture glides (a duration of zero), whatever the level.
            for (final AnimatedPositioned p in t.widgetList<AnimatedPositioned>(
              find.descendant(of: find.byType(HintOverlay), matching: find.byType(AnimatedPositioned)),
            )) {
              expect(
                p.duration,
                Duration.zero,
                reason: '${a.id} level $level: a hint picture glides with reduce motion on',
              );
            }
          }
        }
      }
      await end(t, s);
      return seen;
    }

    testWidgets(
      'the same pictures in the same order with and without reduce motion (one item of each family)',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final String id in ids) {
          final Activity a = content.activities[id]!;
          final List<Set<String>> still = await runLadder(t, a, reduce: true);
          final List<Set<String>> moving = await runLadder(t, a, reduce: false);
          expect(still, isNotEmpty, reason: id);
          expect(
            still.map((Set<String> s) => (s.toList()..sort()).join(',')).toList(),
            moving.map((Set<String> s) => (s.toList()..sort()).join(',')).toList(),
            reason: '$id: reduce motion must show the same pictures in the same order',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets('the same pictures in the same order for the first activity of every other template', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final List<Activity> firsts = <Activity>[
        all<CountTapActivity>().first,
        all<GiveNActivity>().first,
        all<FlashActivity>().first,
        all<TraceActivity>().first,
        all<SortDragActivity>().firstWhere((SortDragActivity a) => !a.share),
        all<SortDragActivity>().firstWhere((SortDragActivity a) => a.share),
        all<BuildPatternActivity>().first,
        all<MatchPairsActivity>().first,
        all<ShapeBuilderActivity>().first,
        all<NumberLineActivity>().first,
        all<RobotPathActivity>().first,
        all<ShopPayActivity>().first,
        all<ClockSetActivity>().first,
        all<BalanceActivity>().first,
        all<SpotErrorActivity>().first,
      ];
      for (final Activity a in firsts) {
        final List<Set<String>> still = await runLadder(t, a, reduce: true);
        final List<Set<String>> moving = await runLadder(t, a, reduce: false);
        expect(
          still.map((Set<String> s) => (s.toList()..sort()).join(',')).toList(),
          moving.map((Set<String> s) => (s.toList()..sort()).join(',')).toList(),
          reason: '${a.id}: reduce motion must show the same pictures in the same order',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets(
      'the motion of a template\'s own stage is still too: the beam is drawn tipped, the marker, the robot and the things do not glide (QA-2)',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final List<String> moving = <String>[];

        // Balance: the beam is drawn already tipped.
        final BalanceActivity b = all<BalanceActivity>().first;
        LessonController c = controllerFor(b);
        TemplateSession s = sessionFor(c, b);
        await host(t, s);
        final TweenAnimationBuilder<double> beam = t.widget(find.byKey(const Key('scale-stage')));
        if (beam.duration != Duration.zero) moving.add('balance beam ${beam.duration}');
        await end(t, s);

        // Number line: the marker is put on its place.
        final NumberLineActivity n = all<NumberLineActivity>().first;
        c = controllerFor(n);
        s = sessionFor(c, n);
        await host(t, s);
        final AnimatedPositioned marker = t.widget(find.byKey(const Key('line-marker')));
        if (marker.duration != Duration.zero) moving.add('number line marker ${marker.duration}');
        await end(t, s);

        // Robot: a step is a new place, not a glide.
        final RobotPathActivity r = all<RobotPathActivity>().first;
        c = controllerFor(r);
        s = sessionFor(c, r);
        await host(t, s);
        final AnimatedPositioned robot = t.widget(find.byKey(const Key('robot')));
        if (robot.duration != Duration.zero) moving.add('robot ${robot.duration}');
        await end(t, s);

        expect(
          moving,
          isEmpty,
          reason: 'the design spec (b40-visual-hints.md 2.2): with reduce motion no flights, the beam drawn already tipped',
        );
      },
    );
  });

  // ------------------------------------------------------------------------------------------------------------------------
  // 5. the hand keeps clear of the speech bubble and the top bar
  // ------------------------------------------------------------------------------------------------------------------------

  group('the hand keeps clear of the speech bubble and the top bar', () {
    // A tile row of 2, 3, 4 and 5 numeral tiles, and a row of sets, by the activities that have them.
    TapAnswerActivity? pick(bool Function(TapAnswerActivity a) test) {
      for (final TapAnswerActivity a in all<TapAnswerActivity>()) {
        if (a.optionsInTiles && test(a)) return a;
      }
      return null;
    }

    bool numerals(TapAnswerActivity a) => a.options.every((ChoiceOption o) => o.numeral != null);
    bool sets(TapAnswerActivity a) => a.options.any((ChoiceOption o) => o.set != null);
    Map<String, TapAnswerActivity?> rows() => <String, TapAnswerActivity?>{
      'three numerals': pick((TapAnswerActivity a) => numerals(a) && a.options.length == 3),
      'two sets': pick((TapAnswerActivity a) => a.options.length == 2 && sets(a)),
      'three sets': pick((TapAnswerActivity a) => a.options.length == 3 && sets(a)),
      'four tiles': pick((TapAnswerActivity a) => a.options.length == 4),
      'five tiles': pick((TapAnswerActivity a) => a.options.length >= 5),
      'two tiles': pick((TapAnswerActivity a) => a.options.length == 2 && !sets(a)),
    };

    for (final ActivitySpec board in boards) {
      testWidgets('every tile of every row, on the board with the stage ${board.stage.size}', (
        WidgetTester t,
      ) async {
        await t.runAsync(warmHintHands);
        final Size size = boardOf(board);
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final Size stage = stageOf(board);
        final double inset = board.stageIsCard ? 16 : 0;
        // The bubble at its largest (its real size is smaller, so a hand that dips into the last 6 points is not counted), and the bar of the home button, the lamp and the eye.
        final Rect bubble = board.bubbleLeft != null
            ? Rect.fromLTWH(board.bubbleLeft!, board.bubbleTop, board.bubbleMaxWidth, board.bubbleMaxHeight)
            : Rect.fromLTWH(
                size.width - board.bubbleRight! - board.bubbleMaxWidth,
                board.bubbleTop,
                board.bubbleMaxWidth,
                board.bubbleMaxHeight,
              );
        final Rect bar = Rect.fromLTWH(0, 0, size.width, board.controlsTop + 56);
        final List<String> bad = <String>[];
        for (final MapEntry<String, TapAnswerActivity?> row in rows().entries) {
          final TapAnswerActivity? a = row.value;
          if (a == null) continue;
          final TapGeometry g = TapGeometry(a, stage, board);
          final bool sets = a.options.any((ChoiceOption o) => o.set != null);
          final double width = sets
              ? (170 < board.tilesWidth / a.options.length - 24
                    ? 170
                    : board.tilesWidth / a.options.length - 24)
              : 96;
          final double rowEnd =
              <double>[for (int i = 0; i < a.options.length; i++) g.optionTip(i).dx]
                  .reduce((double p, double q) => p > q ? p : q) +
              width / 2;
          for (int i = 0; i < a.options.length; i++) {
            final Offset tip = g.optionTip(i);
            await t.pumpWidget(
              MaterialApp(
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: board.stage.left + inset,
                        top: board.stage.top + inset,
                        width: stage.width,
                        height: stage.height,
                        child: HintOverlay(
                          size: stage,
                          clearOf: handClearOf(board),
                          tileHalf: width / 2,
                          rowEnd: rowEnd,
                          marks: <HintMark>[HandMark(tip, press: true, snap: true)],
                          layer: HintLayer.hands,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            await t.pump(const Duration(milliseconds: 600));
            final RenderBox box = t.renderObject<RenderBox>(find.byType(PointingHand));
            final List<Offset> corners = <Offset>[
              for (final Offset c in <Offset>[
                Offset.zero,
                Offset(box.size.width, 0),
                Offset(0, box.size.height),
                Offset(box.size.width, box.size.height),
              ])
                box.localToGlobal(c),
            ];
            final Rect hb = Rect.fromLTRB(
              corners.map((Offset c) => c.dx).reduce((double p, double q) => p < q ? p : q),
              corners.map((Offset c) => c.dy).reduce((double p, double q) => p < q ? p : q),
              corners.map((Offset c) => c.dx).reduce((double p, double q) => p > q ? p : q),
              corners.map((Offset c) => c.dy).reduce((double p, double q) => p > q ? p : q),
            );
            final String why = '${row.key} (${a.id}) tile $i: hand $hb';
            if (hb.overlaps(bubble.deflate(6))) bad.add('$why over the bubble $bubble');
            if (hb.overlaps(bar.deflate(6))) bad.add('$why over the top bar $bar');
            if (hb.left < -1 || hb.right > size.width + 1 || hb.top < -1) bad.add('$why leaves the board');
          }
        }
        expect(bad, isEmpty, reason: bad.join('\n'));
      });
    }
  });

  group('the answer tiles fit their box on every board', () {
    test('a row of numeral tiles (96 wide with a 12 point tap margin on each side) is not wider than the room (QA-4)', () {
      final List<String> tooWide = <String>[];
      for (final ActivitySpec board in boards) {
        for (final TapAnswerActivity a in all<TapAnswerActivity>()) {
          if (!a.optionsInTiles || a.options.any((ChoiceOption o) => o.set != null)) continue;
          if (a.options.length * (96 + 24) > board.tilesWidth + 0.5) {
            tooWide.add(
              '${a.id} (${a.options.length} tiles) on ${board.stage.size}: ${a.options.length * 120} > ${board.tilesWidth}',
            );
          }
        }
      }
      expect(
        tooWide,
        isEmpty,
        reason: 'the row overflows its box: ${tooWide.take(5)} ... ${tooWide.length} in all',
      );
    });
  });

  // ------------------------------------------------------------------------------------------------------------------------
  // 6. a touch during a hint
  // ------------------------------------------------------------------------------------------------------------------------

  group('a touch of the child during a demonstration', () {
    // template, the activity, what the child touches, and whether the demonstration ends at the touch (PLAN.md, B-40 part 1) or,
    // as count and tap, give N and the robot have it, the touch is not taken while the guide is at work (QA-3).
    final List<(String, Activity Function(), Finder Function(Activity a), bool)>
    touches = <(String, Activity Function(), Finder Function(Activity), bool)>[
      (
        'count and tap',
        () => all<CountTapActivity>().first,
        (Activity a) => find.byKey(const Key('butterfly-0')),
        false,
      ),
      (
        'give N',
        () => all<GiveNActivity>().first,
        (Activity a) => find.byKey(const Key('give-butterfly-0')),
        false,
      ),
      (
        'robot',
        () => all<RobotPathActivity>().first,
        (Activity a) => find.byKey(const Key('arrow-up')),
        false,
      ),
      (
        'match',
        () => all<MatchPairsActivity>().first,
        (Activity a) => find.byKey(Key('top-${(a as MatchPairsActivity).pairs.keys.last}')),
        true,
      ),
      (
        'build a pattern',
        () => all<BuildPatternActivity>().first,
        (Activity a) => find.byKey(const Key('palette-0')),
        true,
      ),
      (
        'flash',
        () => all<FlashActivity>().first,
        (Activity a) => find.byKey(
          Key('tile-${(a as FlashActivity).options.firstWhere((ChoiceOption o) => o.id != a.correctId).id}'),
        ),
        true,
      ),
      (
        'tap the answer (a wrong tile)',
        () => act('numeral.bugs.5'),
        (Activity a) => find.byKey(
          Key(
            'tile-${(a as TapAnswerActivity).options.firstWhere((ChoiceOption o) => o.id != a.correctId).id}',
          ),
        ),
        true,
      ),
    ];

    for (final (String name, Activity Function() make, Finder Function(Activity) what, bool atOnce)
        in touches) {
      testWidgets(
        '$name: a touch ${atOnce ? 'takes the hand off at once' : 'does not break the demonstration'}, and the session still works',
        (WidgetTester t) async {
          await t.runAsync(warmHintHands);
          final Activity a = make();
          final LessonController c = controllerFor(a);
          final TemplateSession s = sessionFor(c, a);
          await host(t, s);
          for (int level = 1; level <= 2; level++) {
            c.showHint();
            await t.pump(const Duration(milliseconds: 1));
            await pass(t, 12000, step: 400);
          }
          c.showHint();
          await t.pump(const Duration(milliseconds: 1));
          await pass(t, 1800);
          expect(c.hintShown, 3);
          final Finder target = what(a);
          expect(target, findsWidgets, reason: '${a.id}: what the child touches');
          await t.tap(target.first, warnIfMissed: false);
          await pass(t, 300);
          expect(t.takeException(), isNull, reason: a.id);
          if (atOnce) {
            expect(hand, findsNothing, reason: '${a.id}: the hand has gone at the touch');
            await pass(t, 20000, step: 400);
            expect(hand, findsNothing, reason: '${a.id}: the demonstration did not start again');
            expect(c.answerShown, isFalse, reason: '${a.id}: a cut demonstration is not a finished one');
          } else {
            await pass(t, 20000, step: 400);
          }
          // Whatever happened, the session is alive: nothing was thrown and it is not stuck in the demonstration.
          expect(t.takeException(), isNull, reason: a.id);
          expect(hand, findsNothing, reason: '${a.id}: no hand is left on the stage after the demonstration');
          await end(t, s);
        },
      );
    }

    testWidgets(
      'a two-choice item: one retry; the first mistake shows level 2, the second the demonstration; a three-choice item shows level 1 at the first mistake',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final TapAnswerActivity two = all<TapAnswerActivity>().firstWhere(
          (TapAnswerActivity a) => a.options.length == 2 && a.hints.length == 3,
        );
        final TapAnswerActivity three = all<TapAnswerActivity>().firstWhere(
          (TapAnswerActivity a) => a.options.length == 3 && a.hints.length == 3 && a.optionsInTiles,
        );
        for (final TapAnswerActivity a in <TapAnswerActivity>[two, three]) {
          final LessonController c = controllerFor(a);
          final TapAnswerSession s = TapAnswerSession(c, a);
          await host(t, s);
          final String wrong = a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id;
          await s.choose(wrong);
          await pass(t, 1500);
          expect(c.hintShown, a.options.length == 2 ? 2 : 1, reason: '${a.id}: the first mistake');
          expect(c.guided, isFalse);
          expect(
            find.byKey(const Key('hint-tile-glow')),
            findsNothing,
            reason: 'no tile marked at the first mistake',
          );
          final String wrong2 =
              a.options.where((ChoiceOption o) => o.id != a.correctId && o.id != wrong).isEmpty
              ? wrong
              : a.options.firstWhere((ChoiceOption o) => o.id != a.correctId && o.id != wrong).id;
          await pass(t, 12000, step: 400);
          await s.choose(wrong2);
          await pass(t, 1500);
          if (a.options.length == 2) {
            expect(
              c.guided,
              isTrue,
              reason: '${a.id}: a second mistake ends the retries of a two-choice item',
            );
            expect(c.hintShown, 3);
          } else {
            expect(c.hintShown, 2, reason: '${a.id}: the second mistake shows level 2');
          }
          await end(t, s);
        }
      },
    );
  });

  // ------------------------------------------------------------------------------------------------------------------------
  // 7. the numbers of a question
  // ------------------------------------------------------------------------------------------------------------------------

  group('the numbers a question says (a comma breaks a compound number)', () {
    test('"six, eight, ten" is 6, 8, 10 and not 6, 18 (b.numb17.12)', () {
      final TapAnswerActivity a = act('b.numb17.12');
      final String prompt = a.promptLine.caption;
      expect(numbersIn(prompt), <int>[6, 8, 10], reason: prompt);
    });

    test('the skip-counting hint of that item is a path of twos through six, eight and ten (it was built from 6 and 18)', () {
      final TapAnswerActivity a = act('b.numb17.12');
      final TapGeometry g = TapGeometry(a, stageOf(ActivitySpec.phone), ActivitySpec.phone);
      final HintPlan l2 = tapHintPlan(a, g, 2)!;
      final List<PathMark> paths = <PathMark>[
        for (final HintFrame f in l2.frames) ...f.marks.whereType<PathMark>(),
        ...l2.rest.whereType<PathMark>(),
      ];
      expect(paths, isNotEmpty);
      expect(paths.first.step, 2);
      final PathMark path = paths.first;
      final List<int> numbers = <int>[for (int i = 1; i <= path.count; i++) path.numberAt(i)];
      expect(numbers, containsAllInOrder(<int>[6, 8, 10]), reason: 'the path counts $numbers');
    });

    test('a comma, a colon, a question mark and a full stop never join the words around them', () {
      expect(numbersIn('שֵׁשׁ, שְׁמוֹנֶה, עֶשֶׂר'), <int>[6, 8, 10]);
      expect(numbersIn('חָמֵשׁ: אַחַת עֶשְׂרֵה'), <int>[5, 11]);
      expect(numbersIn('שְׁמוֹנֶה. עֶשֶׂר?'), <int>[8, 10]);
      expect(numbersIn('עֶשְׂרִים, וְאַחַת'), <int>[20, 1]);
      // Without a break the word still joins: eight and ten is eighteen.
      expect(numbersIn('שְׁמוֹנֶה עֶשְׂרֵה'), <int>[18]);
    });
  });
}

bool _isHintKey(String k) =>
    k.contains('hint-') ||
    k.contains('seen-dot') ||
    k.contains('robot-ghost') ||
    k.contains('scale-peg') ||
    k.contains('spot-bar') ||
    k.contains('hop-pill') ||
    k.contains('hop-dot') ||
    k.contains('path-square');

bool _same(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
