import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/play/lesson_arc.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/give_n_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/show_stage.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/trace_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/arc.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The headless playthrough of the lessons in parts (M11 Stage 2, criteria 1 to 5 of docs/milestones/M11-stage2.md section 7.3): a scripted
/// child plays every Shape Forest lesson at ages 4 and 7, new to the skills and having mastered them. No scored opener, a Show writes no evidence,
/// the first meeting writes nothing at Together, the caps hold, and a Show takes what the spec says.
void main() {
  late PackContent content;
  late ShowArt art;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
    art = await ShowArt.load();
  });

  /// The scripted child answers every question right the first time.
  Future<void> answerRight(LessonController c) async {
    final Object a = c.current;
    if (a is ChoiceActivity) {
      // (a tap of several right cards, or a number answer, has no single right option: it is answered as a placement)
      final bool single =
          (a as Activity).json['answer'] is Map<String, Object?> &&
          ((a as Activity).json['answer']! as Map<String, Object?>)['type'] == 'choice' &&
          ((a as Activity).json['answer']! as Map<String, Object?>)['correct'] is String;
      if (single) {
        await c.chooseOption(a.correctId);
      } else {
        await c.submitPlacement(right: true, response: 'done');
      }
    } else {
      await c.submitPlacement(right: true, response: 'done');
    }
  }

  /// Plays the whole visit as the screen and the sessions would: a Show is done by the host and ends with the child's last step, a host's line ends
  /// by itself, and the child answers.
  Future<List<AttemptRecord>?> play(String lessonId, PresentationStage stage, SkillStanding standing) async {
    final List<AttemptRecord> written = <AttemptRecord>[];
    final ArcPlan? plan = planOrNull(content, lessonId, stage, standing);
    // a lesson with no Alone pool has no plan: it is played from its flat list, as before the arc
    if (plan == null) {
      expect(content.lessons[lessonId]!.parts!.alone, isEmpty, reason: lessonId);
      return null;
    }
    final LessonController c = arcController(content, lessonId, plan, written);
    final List<ArcPart> served = <ArcPart>[];
    while (!c.finished) {
      served.add(c.part!);
      if (c.leading) c.leadDone();
      if (c.current.isShow) {
        c.completePractice();
      } else {
        await answerRight(c);
      }
      c.next();
    }
    // the first scored screen is never an opener without teaching: after an optional recall a Show comes first, unless the child has mastered the skills
    final List<ArcPart> afterRecall = served.where((ArcPart p) => p != ArcPart.recall).toList();
    if (standing.showKind != ShowKind.none) expect(afterRecall.first, ArcPart.show, reason: lessonId);
    // caps
    final Map<PresentationStage, int> cap = <PresentationStage, int>{
      PresentationStage.p1: 5,
      PresentationStage.p2: 6,
      PresentationStage.p3: 8,
      PresentationStage.p4: 9,
    };
    expect(served.length, lessThanOrEqualTo(cap[stage]!), reason: '$lessonId at ${stage.name}');
    return written;
  }

  group('every lesson of Shape Forest, a child new to the skills', () {
    for (final (String label, PresentationStage stage) in <(String, PresentationStage)>[
      ('age 4', PresentationStage.p2),
      ('age 7', PresentationStage.p4),
    ]) {
      test(
        '$label: a Show first, no evidence from the Show or the first Together, the rest scored',
        () async {
          int lessons = 0;
          for (final Lesson l in content.lessons.values) {
            if (l.parts == null) continue;
            lessons++;
            final List<AttemptRecord>? written = await play(l.id, stage, newChild);
            if (written == null) continue;
            final Set<String> shows = <String>{
              for (final Activity a in content.activities.values)
                if (a.isShow) a.id,
            };
            expect(written.where((AttemptRecord r) => shows.contains(r.activityId)), isEmpty, reason: l.id);
            // the host did the Together item of a first meeting (a skill whose full Show played; a reminder's Together item is written at hint level 2): nothing of it was written
            final ArcPlan plan = planOf(content, l.id, stage, newChild);
            for (final ArcStep step in plan.steps.where(
              (ArcStep s) => s.part == ArcPart.together && s.firstMeeting,
            )) {
              expect(
                written.where((AttemptRecord r) => r.activityId == step.activity.id),
                isEmpty,
                reason: '${l.id} ${step.activity.id}',
              );
            }
            expect(written, isNotEmpty, reason: '${l.id}: the child\'s own answers in Alone count');
            expect(written.every((AttemptRecord r) => r.result == 'correct'), isTrue);
          }
          expect(lessons, greaterThan(20));
        },
      );
    }
  });

  group('every lesson of Shape Forest, a child who has mastered the skills', () {
    test('no Show and no Together at all, every answer scored', () async {
      for (final Lesson l in content.lessons.values) {
        if (l.parts == null) continue;
        final ArcPlan? plan = planOrNull(content, l.id, PresentationStage.p4, masteredChild);
        if (plan == null) continue;
        expect(
          plan.steps.any((ArcStep s) => s.part == ArcPart.show || s.part == ArcPart.together),
          isFalse,
          reason: l.id,
        );
        final List<AttemptRecord> written = (await play(l.id, PresentationStage.p4, masteredChild))!;
        expect(written.length, plan.steps.length, reason: l.id);
      }
    });
  });

  group('the Show takes what the spec says', () {
    // a full Show: at most 25 seconds for the youngest looks, 30 for the others; a reminder: at most 8 seconds of the host
    testWidgets('every Show of every land, in full and as a reminder', (WidgetTester tester) async {
      final Set<String> done = <String>{};
      final Map<String, int> tooLong = <String, int>{};
      for (final Lesson l in content.lessons.values) {
        final LessonParts? parts = l.parts;
        if (parts == null || !done.add(parts.show)) continue;
        for (final (SkillStanding standing, PresentationStage stage, int limit)
            in <(SkillStanding, PresentationStage, int)>[
              (newChild, PresentationStage.p2, 25000),
              (newChild, PresentationStage.p4, 30000),
              (learningChild, PresentationStage.p4, 8000),
            ]) {
          final ArcPlan? plan = planOrNull(content, l.id, stage, standing);
          if (plan == null) continue;
          final List<AttemptRecord> written = <AttemptRecord>[];
          final LessonController c = arcController(content, l.id, plan, written);
          final Activity show = c.current;
          expect(show.isShow, isTrue, reason: l.id);
          final TemplateSession s = switch (show) {
            SortDragActivity() => SortDragSession(c, show),
            ShapeBuilderActivity() => ShapeBuilderSession(c, show),
            TraceActivity() => TraceSession(c, show),
            NumberLineActivity() => NumberLineSession(c, show),
            GiveNActivity() => GiveNSession(c, show),
            CountTapActivity() => CountTapSession(c, show),
            BuildPatternActivity() => BuildPatternSession(c, show),
            BalanceActivity() => BalanceSession(c, show),
            ShopPayActivity() => ShopPaySession(c, show),
            RobotPathActivity() => RobotPathSession(c, show),
            ClockSetActivity() => ClockSetSession(c, show),
            _ => throw StateError(show.template),
          };
          s.slowHost = stage == PresentationStage.p2;
          s.showStyle = ShowStyle(
            art: art,
            deep: const Color(0xFF1E7F4C),
            lip: const Color(0xFF1E7F4C),
            slow: stage == PresentationStage.p2,
          );
          await hostSession(tester, s);
          s.startHost();
          int spent = 0;
          while (spent < 60000) {
            await tester.pump(const Duration(milliseconds: 100));
            spent += 100;
            // (a Show that asks for a guess waits for the child's touch, which is not the host's time: the scripted child guesses at once)
            final ShowPredict? asked = s.predicting.value;
            if (asked != null) s.guess(asked.choices.first.id);
            if (!s.hosting) break;
          }
          expect(s.hosting, isFalse, reason: '${show.id} is over');
          if (spent > limit) tooLong['${show.id} ${standing.showKind.name} ${stage.name}'] = spent;
          expect(written, isEmpty);
          s.dispose();
          await tester.pumpWidget(const SizedBox());
        }
      }
      // A Show over its time is content (too many moves for the look, or a line too long): named here with the time it takes, for the curriculum-expert to
      // shorten; the list may only get shorter.
      // ignore: avoid_print
      print('SHOWS OVER THEIR TIME: $tooLong');
      expect(tooLong.keys.toSet(), _showsOverTheirTime, reason: '$tooLong');
    });
  });
}

/// The Shows that take longer than the spec allows (M11-stage2 section 2.4: 25 seconds at P1 and P2, 30 at P3 and P4, 8 for a reminder), as `show look look`;
/// each is for the curriculum-expert to shorten (fewer host moves, or shorter lines). A Show that is shortened comes off the list.
const Set<String> _showsOverTheirTime = <String>{};
