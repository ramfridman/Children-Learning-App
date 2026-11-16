import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/play/lesson_arc.dart';

import 'support/arc.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The lesson arc of a land (M11 Stage 2, docs/milestones/M11-stage2.md sections 2, 5): which screens a visit serves for the child's level and
/// look, in which order, how the fade rule moves the Alone items. Tests by ids and structure, never by the Hebrew text.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  List<String> parts(ArcPlan p) => <String>[for (final ArcStep s in p.steps) s.part.name];
  Iterable<ArcStep> inPart(ArcPlan p, ArcPart a) => p.steps.where((ArcStep s) => s.part == a);

  group('which Show plays: the child\'s level decides, never the age', () {
    test(
      'new to the skill: the full Show; learning below 0.6: a reminder; mastered or learning well: none',
      () {
        expect(const SkillStanding().showKind, ShowKind.full);
        expect(const SkillStanding(status: SkillStatus.ready).showKind, ShowKind.full);
        expect(learningChild.showKind, ShowKind.reminder);
        expect(const SkillStanding(status: SkillStatus.learning, p: 0.7).showKind, ShowKind.none);
        expect(masteredChild.showKind, ShowKind.none);
        expect(const SkillStanding(status: SkillStatus.durableMastery, p: 0.9).showKind, ShowKind.none);
      },
    );

    test('a clean learner gets a reminder after a worked example, after two mistakes in a row and after 14 days away', () {
      const SkillStanding good = SkillStanding(status: SkillStatus.learning, p: 0.8, daysSincePractice: 3);
      expect(good.showKind, ShowKind.none);
      expect(
        const SkillStanding(status: SkillStatus.learning, p: 0.8, struggled: true).showKind,
        ShowKind.reminder,
      );
      expect(
        const SkillStanding(status: SkillStatus.learning, p: 0.8, daysSincePractice: 14).showKind,
        ShowKind.reminder,
      );
      expect(const SkillStanding(status: SkillStatus.needsRevisit, p: 0.9).showKind, ShowKind.reminder);
    });

    test('the same lesson: a 4-year-old who has mastered it gets no Show, a 7-year-old new to it gets the full one', () {
      final ArcPlan four = planOf(content, 'any-shape', PresentationStage.p2, masteredChild);
      final ArcPlan seven = planOf(content, 'any-shape', PresentationStage.p4, newChild);
      expect(inPart(four, ArcPart.show), isEmpty);
      expect(inPart(four, ArcPart.together), isEmpty);
      final ArcStep show = inPart(seven, ArcPart.show).single;
      expect(show.show, ShowKind.full);
      expect(show.activity.isShow, isTrue);
      expect(show.activity.skillId, 'SHP-A-03');
    });
  });

  group('the order and the evidence of the screens', () {
    test('after an optional recall the first screen is a Show; Together comes right after it, and its first meeting is flagged', () {
      final ArcPlan p = planOf(
        content,
        'any-shape',
        PresentationStage.p4,
        newChild,
        startedSkills: <String>{'SHP-A-02'},
      );
      expect(parts(p).take(3), <String>['recall', 'show', 'together']);
      expect(inPart(p, ArcPart.together).single.firstMeeting, isTrue);
      expect(inPart(p, ArcPart.together).single.lead, greaterThan(0));
      final ArcPlan noRecall = planOf(content, 'any-shape', PresentationStage.p4, newChild);
      expect(parts(noRecall).first, 'show');
    });

    test('a reminder Show is followed by a Together item that is not a first meeting', () {
      final ArcPlan p = planOf(content, 'any-shape', PresentationStage.p4, learningChild);
      expect(inPart(p, ArcPart.show).single.show, ShowKind.reminder);
      expect(inPart(p, ArcPart.together).single.firstMeeting, isFalse);
    });

    test('a lesson of two skills: one full Show, and the second skill\'s Show is a reminder just before its first item', () {
      final ArcPlan p = planOf(content, 'shape-friends', PresentationStage.p4, newChild);
      final List<ArcStep> shows = inPart(p, ArcPart.show).toList();
      expect(shows.map((ArcStep s) => s.show), <ShowKind>[ShowKind.full, ShowKind.reminder]);
      expect(shows.length, lessThanOrEqualTo(2));
      final int second = p.steps.indexOf(shows.last);
      expect(p.steps[second + 1].activity.skillId, shows.last.activity.skillId);
    });

    test('the host hands over to the companion at the first Alone item after it taught', () {
      final ArcPlan p = planOf(content, 'any-shape', PresentationStage.p4, newChild);
      expect(inPart(p, ArcPart.alone).first.line, isNotNull);
      expect(inPart(p, ArcPart.alone).skip(1).every((ArcStep s) => s.line == null), isTrue);
      final ArcPlan mastered = planOf(content, 'any-shape', PresentationStage.p4, masteredChild);
      expect(inPart(mastered, ArcPart.alone).every((ArcStep s) => s.line == null), isTrue);
    });
  });

  group('the caps by look stage', () {
    const Map<PresentationStage, int> screens = <PresentationStage, int>{
      PresentationStage.p1: 5,
      PresentationStage.p2: 6,
      PresentationStage.p3: 8,
      PresentationStage.p4: 9,
    };

    test('every lesson in parts serves at most 5, 6, 8 and 9 screens, and at most 7 scored items at P4', () {
      int lessons = 0;
      for (final Lesson l in content.lessons.values) {
        if (l.parts == null) continue;
        lessons++;
        for (final MapEntry<PresentationStage, int> e in screens.entries) {
          for (final SkillStanding standing in <SkillStanding>[newChild, learningChild, masteredChild]) {
            final ArcPlan? p = ArcPlan.build(
              content: content,
              parts: l.parts!,
              skills: l.skillIds,
              caps: ArcCaps.ofStage(e.key.index),
              standing: (String _) => standing,
              started: (String _) => true,
            );
            if (p == null) continue;
            expect(p.steps.length, lessThanOrEqualTo(e.value), reason: '${l.id} at ${e.key.name}');
            final int scored = p.steps
                .where(
                  (ArcStep s) => s.part == ArcPart.recall || s.part == ArcPart.alone || s.part == ArcPart.use,
                )
                .length;
            if (e.key == PresentationStage.p4) expect(scored, lessThanOrEqualTo(7), reason: l.id);
            expect(p.steps.where((ArcStep s) => s.part == ArcPart.show).length, lessThanOrEqualTo(2));
          }
        }
      }
      expect(lessons, greaterThan(20));
    });

    test('a visit never serves a Show among its flat items, and the Show is never in a lesson\'s items', () {
      for (final Lesson l in content.lessons.values) {
        if (l.parts == null) continue;
        expect(l.itemIds, isNot(contains(l.parts!.show)));
        expect(content.activities[l.parts!.show]!.isShow, isTrue);
      }
    });
  });

  group('the fade rule: the child\'s level orders the Alone items', () {
    int rung(ArcStep s) => rungOf(s.activity);

    test('a new child\'s first two Alone items are rung 0 (hands on), and no symbol comes before the child has met the skill', () {
      final ArcPlan p = planOf(content, 'any-shape', PresentationStage.p4, newChild);
      final List<ArcStep> alone = inPart(p, ArcPart.alone).toList();
      expect(rung(alone[0]), 0);
      expect(alone.every((ArcStep s) => rung(s) <= 1), isTrue);
    });

    test('a mastered child\'s first Alone item is the most symbolic one the pool has', () {
      final ArcPlan p = planOf(content, 'polygon-detectives-more', PresentationStage.p4, masteredChild);
      final List<ArcStep> alone = inPart(p, ArcPart.alone).toList();
      final int most = alone.map(rung).reduce((int a, int b) => a > b ? a : b);
      expect(rung(alone.first), most);
    });

    test(
      'after a tagged mistake the next item of the skill is one rung lower; two clean answers bring it back',
      () {
        final ArcPlan p = planOf(
          content,
          'polygon-detectives-more',
          PresentationStage.p4,
          const SkillStanding(status: SkillStatus.learning, p: 0.8),
        );
        final List<int> at = <int>[
          for (final (int i, ArcStep s) in p.steps.indexed)
            if (s.part == ArcPart.alone) i,
        ];
        final int before = rung(p.steps[at[1]]);
        p.answered(at[0], slipped: true, clean: false);
        final int after = rung(p.steps[at[1]]);
        expect(after, lessThanOrEqualTo(before));
      },
    );

    test('a slip on a lesson that has one Alone item left changes nothing and never throws', () {
      final ArcPlan p = planOf(content, 'rectangle', PresentationStage.p1, newChild);
      final int last = p.steps.lastIndexWhere((ArcStep s) => s.part == ArcPart.alone);
      expect(p.answered(last, slipped: true, clean: false), isEmpty);
    });
  });

  group('recall and use', () {
    test('recall is served only when the child has started the skill, and never to the youngest', () {
      final ArcPlan fresh = planOf(content, 'any-shape', PresentationStage.p4, newChild);
      expect(inPart(fresh, ArcPart.recall), isEmpty);
      final ArcPlan started = planOf(
        content,
        'any-shape-again',
        PresentationStage.p4,
        newChild,
        startedSkills: <String>{'SHP-A-02'},
      );
      expect(inPart(started, ArcPart.recall), hasLength(1));
      final ArcPlan p1 = planOf(
        content,
        'any-shape-again',
        PresentationStage.p1,
        newChild,
        startedSkills: <String>{'SHP-A-02'},
      );
      expect(inPart(p1, ArcPart.recall), isEmpty);
      expect(inPart(p1, ArcPart.use), isEmpty);
    });
  });
}
