import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/play/lesson_arc.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/template_session.dart';

import 'fakes.dart';

/// A child who has never met a skill, one who is learning it (p 0.5), and one who has mastered it.
const SkillStanding newChild = SkillStanding();
const SkillStanding learningChild = SkillStanding(status: SkillStatus.learning, p: 0.5);
const SkillStanding masteredChild = SkillStanding(status: SkillStatus.freshMastery, p: 0.95);

/// The visit of [lessonId] for a child at [stage] whose standing in every skill is [standing]; [startedSkills] are the skills it has begun. Null
/// for a lesson whose Alone pool is empty: it is played from its flat list.
ArcPlan? planOrNull(
  PackContent content,
  String lessonId,
  PresentationStage stage,
  SkillStanding standing, {
  Set<String> startedSkills = const <String>{},
}) {
  final Lesson lesson = content.lessons[lessonId]!;
  return ArcPlan.build(
    content: content,
    parts: lesson.parts!,
    skills: lesson.skillIds,
    caps: ArcCaps.ofStage(stage.index),
    standing: (String _) => standing,
    started: startedSkills.contains,
  );
}

/// [planOrNull] for a lesson that has a plan.
ArcPlan planOf(
  PackContent content,
  String lessonId,
  PresentationStage stage,
  SkillStanding standing, {
  Set<String> startedSkills = const <String>{},
}) => planOrNull(content, lessonId, stage, standing, startedSkills: startedSkills)!;

/// A controller on the visit [plan], with a host (so that a Show and the host's lead are host moments) and every attempt written to [written].
LessonController arcController(
  PackContent content,
  String lessonId,
  ArcPlan plan,
  List<AttemptRecord> written,
) {
  final LessonController c = LessonController(
    content: content,
    lesson: content.lessons[lessonId]!,
    profileId: 'p-1',
    clock: FixedClock(1793000000000),
    record: (AttemptRecord r) async => written.add(r),
    arc: plan,
    hostGreeting: const Spoken(vo: 'vo:test.greeting', caption: 'greeting'),
  );
  // the host's greeting is over (the screen ends it after its pause)
  c.endGreeting();
  return c;
}

/// Moves the controller to the first step of [part].
void goTo(LessonController c, ArcPart part) {
  while (c.part != part) {
    c.next();
  }
  // a host's line that leads nothing ends by itself in the app (the screen's timer); here the test ends it
}

/// Puts [s] on a phone-sized stage.
Future<void> hostSession(WidgetTester tester, TemplateSession s) async {
  const ActivitySpec spec = ActivitySpec.phone;
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Builder(
            builder: (BuildContext ctx) => Center(
              child: SizedBox(
                width: spec.tilesWidth,
                height: spec.stage.height + 160,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: spec.stage.width,
                      height: spec.stage.height,
                      child: s.buildStage(ctx, spec.stage.size, spec),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: spec.tilesWidth,
                        child: s.buildTiles(ctx, spec) ?? const SizedBox(),
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
  await tester.pump(const Duration(milliseconds: 100));
}

/// Moves time forward in steps of 100 ms.
Future<void> passTime(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}
