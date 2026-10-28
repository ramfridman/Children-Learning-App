import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/flash_session.dart';
import 'package:nitznutz/play/give_n_session.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/trace_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/tap_answer_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The headless playthrough (M9): a simulated child plays every activity of the real pack, the way a child can go
/// wrong and right, and nothing may crash, dead-end or leave the child without a next step. It is the release gate's
/// proof that the content works; the printed coverage shows what it reached.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];
  final Set<String> reachedTags = <String>{};
  final Set<String> reachedActions = <String>{};
  final Set<String> reachedTemplates = <String>{};
  int activitiesPlayed = 0;

  LessonController start(Lesson lesson, int index) {
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

  /// What a child can do on [a] that is wrong: each option, or each wrong number to give.
  List<Future<Outcome> Function(LessonController)> wrongMoves(Activity a) => switch (a) {
    TapAnswerActivity() => <Future<Outcome> Function(LessonController)>[
      for (final ChoiceOption o in a.options)
        if (o.id != a.correctId) (LessonController c) => c.chooseOption(o.id),
    ],
    CountTapActivity() => <Future<Outcome> Function(LessonController)>[
      for (final ChoiceOption o in a.options)
        if (o.id != a.correctId) (LessonController c) => c.chooseOption(o.id),
    ],
    FlashActivity() => <Future<Outcome> Function(LessonController)>[
      for (final ChoiceOption o in a.options)
        if (o.id != a.correctId) (LessonController c) => c.chooseOption(o.id),
    ],
    SortDragActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    BuildPatternActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    RobotPathActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    ShapeBuilderActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    NumberLineActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
      if (a.mirrorTag != null) (LessonController c) => c.submitPlacement(right: false, tag: a.mirrorTag!),
    ],
    BalanceActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    SpotErrorActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    MatchPairsActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
    ],
    ShopPayActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
      if (a.countTag != null) (LessonController c) => c.submitPlacement(right: false, tag: a.countTag!),
    ],
    ClockSetActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
      if (a.handsTag != null) (LessonController c) => c.submitPlacement(right: false, tag: a.handsTag!),
    ],
    TraceActivity() => <Future<Outcome> Function(LessonController)>[
      (LessonController c) => c.submitPlacement(right: false, tag: a.wrongTag ?? ''),
      if (a.directionTag != null)
        (LessonController c) => c.submitPlacement(right: false, tag: a.directionTag!),
    ],
    GiveNActivity() => <Future<Outcome> Function(LessonController)>[
      for (final int n in <int>{
        if (a.n > 1) a.n - 1,
        if (a.n < a.sourceCount) a.n + 1,
        a.sourceCount,
      }..remove(a.n))
        (LessonController c) => c.giveN(n),
    ],
  };

  Future<Outcome> right(LessonController c) {
    final Activity a = c.current;
    return switch (a) {
      TapAnswerActivity() => c.chooseOption(a.correctId),
      CountTapActivity() => c.chooseOption(a.correctId),
      FlashActivity() => c.chooseOption(a.correctId),
      GiveNActivity() => c.giveN(a.n),
      SortDragActivity() => c.submitPlacement(right: true),
      BuildPatternActivity() => c.submitPlacement(right: true),
      RobotPathActivity() => c.submitPlacement(right: true),
      ShapeBuilderActivity() => c.submitPlacement(right: true),
      NumberLineActivity() => c.submitPlacement(right: true),
      BalanceActivity() => c.submitPlacement(right: true),
      SpotErrorActivity() => c.submitPlacement(right: true),
      MatchPairsActivity() => c.submitPlacement(right: true),
      ShopPayActivity() => c.submitPlacement(right: true),
      ClockSetActivity() => c.submitPlacement(right: true),
      TraceActivity() => c.submitPlacement(right: true),
    };
  }

  test('every lesson of the pack, every activity: wrong moves, the ladder of help, unsure, then right', () async {
    for (final Lesson lesson in content.lessons.values) {
      final int n = lesson.itemIds.length;
      for (int i = 0; i < n; i++) {
        final String where = '${lesson.id}[$i]';
        final Activity a = content.activities[lesson.itemIds[i]]!;
        reachedTemplates.add(a.template);
        activitiesPlayed++;

        // 1. each wrong move, on a fresh start: the first mistake gets the line of its misconception
        for (final Future<Outcome> Function(LessonController) move in wrongMoves(a)) {
          final LessonController c = start(lesson, i);
          expect(c.current.id, a.id, reason: where);
          final Outcome o = await move(c);
          expect(o.correct, isFalse, reason: where);
          expect(c.feedback, FeedbackKind.notYet, reason: where);
          expect(c.bubble, a.feedback.forIncorrect(o.tag.isEmpty ? null : o.tag).caption, reason: where);
          if (o.tag.isNotEmpty) reachedTags.add(o.tag);
          expect(c.finished, isFalse, reason: where);
        }

        // 2. the child keeps going wrong: the help climbs the whole ladder, then only the right move is left
        final List<Future<Outcome> Function(LessonController)> wrong = wrongMoves(a);
        final LessonController ladder = start(lesson, i);
        for (int k = 0; k < a.maxAttempts; k++) {
          await wrong[k % wrong.length](ladder);
        }
        expect(ladder.guided, isTrue, reason: '$where: after ${a.maxAttempts} mistakes the child is guided');
        if (a.hints.isNotEmpty) {
          expect(ladder.hintLevel, a.hints.length, reason: '$where: the ladder reaches its top');
          reachedActions.add(ladder.hintAction!.name);
        }
        expect((await right(ladder)).correct, isTrue, reason: '$where: a guided child can still answer');

        // 3. the lamp, level by level, never past the top and never a dead end
        final LessonController lamp = start(lesson, i);
        for (int h = 1; h <= a.hints.length + 1; h++) {
          lamp.showHint();
          expect(lamp.hintLevel, h <= a.hints.length ? h : a.hints.length, reason: where);
          if (lamp.hintAction != null) reachedActions.add(lamp.hintAction!.name);
          expect(
            lamp.bubble,
            a.hints[(h <= a.hints.length ? h : a.hints.length) - 1].say.caption,
            reason: where,
          );
        }

        // 4. "I'm not sure" is welcomed, not marked wrong
        final LessonController unsure = start(lesson, i);
        final int before = written.length;
        await unsure.unsure();
        expect(written.length, before + 1, reason: where);
        expect(written.last.result, 'unsure', reason: where);
        expect(unsure.errors, 0, reason: '$where: unsure is not a mistake');
        expect((await right(unsure)).correct, isTrue, reason: where);
      }

      // 5. a child who is right every time reaches the celebration
      final LessonController through = start(lesson, 0);
      for (int i = 0; i < n; i++) {
        expect((await right(through)).correct, isTrue, reason: '${lesson.id}[$i]');
        through.next();
      }
      expect(through.finished, isTrue, reason: lesson.id);
      expect(through.bubble, lesson.celebration.caption, reason: lesson.id);
    }
    printOnFailure('reached: $reachedTemplates $reachedTags $reachedActions');
  });

  test('coverage: the whole pack was reached, every tag and every kind of help', () {
    expect(activitiesPlayed, greaterThanOrEqualTo(content.activities.length - 1));
    expect(
      reachedTemplates,
      containsAll(<String>[
        'tap_answer',
        'count_tap',
        'give_n',
        'flash',
        'sort_drag',
        'build_pattern',
        'robot_path',
        'shape_builder',
        'number_line',
        'balance',
        'spot_error',
        'match_pairs',
        'shop_pay',
        'clock_set',
        'trace',
      ]),
    );
    // Every misconception a wrong answer can carry was produced by some wrong move, and has a line of its own.
    final Set<String> authored = <String>{
      for (final Activity a in content.activities.values) ...a.engineTags,
    };
    expect(reachedTags, containsAll(authored.where((String t) => !_traceOnly.contains(t))));
    expect(reachedActions, containsAll(<String>['replayPromptSlow', 'showFingers', 'workedExample']));
    // ignore: avoid_print
    print(
      'PLAYTHROUGH: ${content.lessons.length} lessons, $activitiesPlayed activities, templates $reachedTemplates, '
      'tags ${reachedTags.length}/${authored.length}, kinds of help $reachedActions',
    );
  });

  test(
    'every skill has enough to learn from, every activity is in a lesson, and the prerequisites exist',
    () {
      final Set<String> inLessons = <String>{for (final Lesson l in content.lessons.values) ...l.itemIds};
      for (final String id in content.activities.keys) {
        expect(inLessons, contains(id), reason: '$id is in no lesson');
      }
      for (final SkillDoc s in content.skills.values) {
        final int n = content.activities.values
            .where((Activity a) => a.skills.any((Skill k) => k.id == s.id))
            .length;
        if (s.id.startsWith('NUM-A-')) {
          expect(n, greaterThanOrEqualTo(3), reason: '${s.id} has $n activities');
        }
        for (final String p in s.prerequisites.keys) {
          expect(content.skills, contains(p), reason: '${s.id} needs $p, which is not in the pack');
        }
      }
    },
  );

  group('the stage of every activity, on every screen', () {
    for (final (String, ActivitySpec) device in <(String, ActivitySpec)>[
      ('phone', ActivitySpec.phone),
      ('tablet landscape', ActivitySpec.tabletLandscape),
      ('tablet portrait', ActivitySpec.tabletPortrait),
    ]) {
      testWidgets('builds without an error and can be answered on a ${device.$1}', (
        WidgetTester tester,
      ) async {
        for (final Lesson lesson in content.lessons.values) {
          for (int i = 0; i < lesson.itemIds.length; i++) {
            final LessonController c = start(lesson, i);
            final Activity a = c.current;
            final TemplateSession s = switch (a) {
              CountTapActivity() => CountTapSession(c, a),
              TapAnswerActivity() => TapAnswerSession(c, a),
              FlashActivity() => FlashSession(c, a),
              GiveNActivity() => GiveNSession(c, a),
              SortDragActivity() => SortDragSession(c, a),
              BuildPatternActivity() => BuildPatternSession(c, a),
              RobotPathActivity() => RobotPathSession(c, a),
              ShapeBuilderActivity() => ShapeBuilderSession(c, a),
              NumberLineActivity() => NumberLineSession(c, a),
              BalanceActivity() => BalanceSession(c, a),
              SpotErrorActivity() => SpotErrorSession(c, a),
              MatchPairsActivity() => MatchPairsSession(c, a),
              ShopPayActivity() => ShopPaySession(c, a),
              ClockSetActivity() => ClockSetSession(c, a),
              TraceActivity() => TraceSession(c, a),
            };
            await tester.pumpWidget(
              MaterialApp(
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: Builder(
                      builder: (BuildContext ctx) => Center(
                        child: SizedBox(
                          width: device.$2.tilesWidth,
                          height: device.$2.stage.height + 160,
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                width: device.$2.stage.width,
                                height: device.$2.stage.height,
                                child: s.buildStage(ctx, device.$2.stage.size, device.$2),
                              ),
                              Expanded(
                                child: SizedBox(
                                  width: device.$2.tilesWidth,
                                  child: s.buildTiles(ctx, device.$2) ?? const SizedBox(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 2500));
            expect(tester.takeException(), isNull, reason: '${lesson.id}[$i] ${a.id}');
            s.dispose();
            await tester.pumpWidget(const SizedBox());
          }
        }
      });
    }
  });
}

/// Tags that come from watching the touches (a count template's trace), not from a wrong option.
const Set<String> _traceOnly = <String>{};
