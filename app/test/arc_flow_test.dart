import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/play/lesson_arc.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/rooms/moments.dart';

import 'support/arc.dart';
import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The Show, the host's lead and the evidence rules of a lesson in parts (M11 Stage 2, docs/milestones/M11-stage2.md sections 2.2 and 2.3), and the
/// two template records the pilot needed: a card's own tag in a sort, a piece's tag in a shape builder, and equal pieces that are interchangeable.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];
  setUp(written.clear);

  LessonController visit(
    String lesson,
    SkillStanding standing, {
    PresentationStage stage = PresentationStage.p4,
  }) => arcController(content, lesson, planOf(content, lesson, stage, standing), written);

  group('the Show writes nothing, whatever happens', () {
    test('a Show is a host moment, offers no help, and its end writes no attempt', () async {
      final LessonController c = visit('any-shape', newChild);
      expect(c.part, ArcPart.show);
      expect(c.moment, Moment.show);
      expect(c.moment.speaker, Speaker.host);
      expect(c.noHelp, isTrue);
      await c.unsure();
      c.showHint();
      c.completePractice();
      c.next();
      expect(written, isEmpty);
      expect(c.part, ArcPart.together);
    });

    test('a wrong move in a Show writes nothing and is no mistake', () async {
      final LessonController c = visit('any-shape', newChild);
      final Outcome o = await c.submitPlacement(right: false, tag: 'M-SHP-CLOSED');
      expect(o.correct, isFalse);
      expect(written, isEmpty);
      expect(c.errors, 0);
    });

    test('the Show is no item of the engine\'s catalogue', () {
      final Object catalogItems = content.activities.values.where((Activity a) => a.isShow).length;
      expect(catalogItems, greaterThan(10));
      for (final Activity a in content.activities.values.where((Activity a) => a.isShow)) {
        expect(a.unscored, isTrue, reason: a.id);
      }
    });
  });

  group('Together: the host\'s lead, and what it counts for', () {
    test('on a first meeting the host leads, then the companion asks, and the answer writes nothing: right, wrong or unsure', () async {
      final LessonController c = visit('any-shape', newChild);
      goTo(c, ArcPart.together);
      expect(c.leading, isTrue);
      expect(c.moment, Moment.lead);
      expect(c.noHelp, isTrue);
      c.leadDone();
      expect(c.moment, Moment.turn);
      expect(c.leading, isFalse);
      await c.submitPlacement(right: false, tag: 'M-SHP-PROTO');
      await c.unsure();
      await c.submitPlacement(right: true, response: 'sorted');
      expect(written, isEmpty);
    });

    test('on a later visit (a reminder) the answer is written as an answer given at hint level 2', () async {
      final LessonController c = visit('any-shape', learningChild);
      goTo(c, ArcPart.together);
      c.leadDone();
      await c.submitPlacement(right: false, tag: 'M-SHP-PROTO');
      await c.submitPlacement(right: true, response: 'sorted');
      expect(written.map((AttemptRecord r) => r.result), <String>['incorrect', 'correct']);
      expect(written.every((AttemptRecord r) => r.hintLevel >= 2), isTrue);
      expect(written.first.misconceptionTag, 'M-SHP-PROTO');
    });

    test('Alone is scored as always, also on a first meeting: a wrong answer writes its tag, a right one at hint level 0', () async {
      final LessonController c = visit('any-shape', newChild);
      goTo(c, ArcPart.alone);
      // the hand-over to the companion is the host's line; then the companion asks
      expect(c.leading, isTrue);
      c.leadDone();
      await c.submitPlacement(right: false, tag: 'M-SHP-PROTO');
      await c.submitPlacement(right: true, response: 'sorted');
      expect(written, hasLength(2));
      expect(written.last.result, 'correct');
      expect(written.last.hintLevel, lessThan(2));
      expect(written.first.misconceptionTag, 'M-SHP-PROTO');
    });

    test('a child who has mastered the skill gets no Show and no Together: the first screen is Alone, and it is scored', () async {
      final LessonController c = visit('any-shape', masteredChild, stage: PresentationStage.p2);
      expect(c.part, ArcPart.alone);
      expect(c.arc!.steps.any((ArcStep s) => s.part == ArcPart.show || s.part == ArcPart.together), isFalse);
      expect(c.moment, Moment.turn);
      await c.submitPlacement(right: true, response: 'sorted');
      expect(written, hasLength(1));
    });
  });

  group('the fade rule moves the next item after a mistake', () {
    test('a tagged mistake in Alone puts the controller\'s next item where the plan put it', () async {
      final LessonController c = visit(
        'polygon-detectives-more',
        const SkillStanding(status: SkillStatus.learning, p: 0.8),
      );
      goTo(c, ArcPart.alone);
      c.leadDone();
      await c.submitPlacement(right: false, tag: 'M-SHP-CLOSED');
      await c.submitPlacement(right: true, response: 'sorted');
      c.next();
      for (int i = 0; i < c.items.length; i++) {
        expect(c.items[i].id, c.arc!.steps[i].activity.id, reason: 'step $i');
      }
    });
  });

  group('the host\'s part on the stage', () {
    testWidgets(
      'a sort Show: the host sorts every card but the last; the child sorts the last; nothing is written',
      (WidgetTester tester) async {
        final LessonController c = visit('any-shape', newChild);
        final SortDragSession s = SortDragSession(c, c.current as SortDragActivity);
        await hostSession(tester, s);
        s.startHost();
        await tester.pump();
        expect(s.hosting, isTrue);
        // the child's touch is not a move while the host acts
        await s.drop(s.activity.items.first.id, 'b1');
        expect(s.placed, isEmpty);
        await passTime(tester, 40000);
        expect(s.hosting, isFalse);
        final String last = s.activity.show!.childStep.item!;
        expect(s.placed.keys, isNot(contains(last)));
        expect(s.placed.length, s.activity.items.length - 1);
        // a wrong bin: "let's look again", nothing is written, the card waits
        final String right = s.activity.show!.childStep.bin!;
        final String wrong = s.activity.bins.firstWhere((SortBin b) => b.id != right).id;
        await s.drop(last, wrong);
        await passTime(tester, 1200);
        expect(s.placed, isNot(contains(last)));
        expect(written, isEmpty);
        // the right bin ends the Show
        await s.drop(last, right);
        expect(c.solved, isTrue);
        await passTime(tester, 3000);
        expect(c.part, ArcPart.together);
        expect(written, isEmpty);
      },
    );

    testWidgets('a shape-builder Show: the host fills all places but one, any fitting piece finishes it', (
      WidgetTester tester,
    ) async {
      final Lesson l = content.lessons['shape-friends']!;
      final ArcPlan plan = planOf(content, l.id, PresentationStage.p4, newChild);
      final LessonController c = arcController(content, l.id, plan, written);
      expect(c.current, isA<ShapeBuilderActivity>());
      final ShapeBuilderSession s = ShapeBuilderSession(c, c.current as ShapeBuilderActivity);
      await hostSession(tester, s);
      s.startHost();
      await passTime(tester, 40000);
      expect(s.hosting, isFalse);
      expect(s.filled.length, s.activity.slots.length - 1);
      final ShapeSlot open = s.activity.slots.firstWhere((ShapeSlot x) => !s.filled.contains(x.id));
      // a piece that does not belong (the tray of this Show has none: then only the right one is tried)
      final int wrongPiece = <int>[for (int i = 0; i < s.pieces.length; i++) i]
          .indexWhere((int i) => !s.isUsed(i) && !ShapeBuilderActivity.fits(s.pieces[i], open));
      if (wrongPiece >= 0) {
        await s.drop(wrongPiece, open.id);
        await passTime(tester, 1200);
        expect(s.filled, isNot(contains(open.id)));
      }
      expect(written, isEmpty);
      final int piece = <int>[for (int i = 0; i < s.pieces.length; i++) i]
          .firstWhere((int i) => !s.isUsed(i) && ShapeBuilderActivity.fits(s.pieces[i], open));
      await s.drop(piece, open.id);
      expect(c.solved, isTrue);
      expect(written, isEmpty);
      await passTime(tester, 3000);
      s.dispose();
    });

    testWidgets(
      'a Together lead: the host sorts the first card, then the companion\'s turn; a wrong card keeps its own tag',
      (WidgetTester tester) async {
        final LessonController c = visit('any-shape', learningChild);
        goTo(c, ArcPart.together);
        final SortDragSession s = SortDragSession(c, c.current as SortDragActivity);
        await hostSession(tester, s);
        final int lead = c.step!.lead;
        s.startHost();
        await passTime(tester, 20000);
        expect(c.leading, isFalse);
        expect(s.placed.length, lead);
        expect(c.moment, Moment.turn);
        // a card of the sort that has a tag of its own is written with that tag, not the activity's
        final SortItem tagged = s.activity.items.firstWhere(
          (SortItem i) => i.misconception != null && !s.placed.containsKey(i.id),
        );
        final String wrongBin = s.activity.bins.firstWhere((SortBin b) => b.id != tagged.bin).id;
        await s.drop(tagged.id, wrongBin);
        await passTime(tester, 1200);
        expect(written.single.misconceptionTag, tagged.misconception);
        expect(written.single.hintLevel, greaterThanOrEqualTo(2));
        // the help the mistake asked for plays out
        await passTime(tester, 8000);
        s.dispose();
      },
    );
  });

  group('equal pieces are interchangeable (the rocket)', () {
    test('a colour does not make another shape: the nose and the fins are all triangles', () {
      expect(
        ShapeBuilderActivity.shapeClassOf('asset:shape_triangle_red'),
        ShapeBuilderActivity.shapeClassOf('asset:shape_triangle_green'),
      );
      expect(ShapeBuilderActivity.shapeClassOf('asset:shape_triangle'), 'asset:shape_triangle');
      expect(ShapeBuilderActivity.shapeClassOf('asset:shape_triangle_thin'), 'asset:shape_triangle_thin');
      expect(ShapeBuilderActivity.shapeClassOf('asset:shape_triangle_half'), 'asset:shape_triangle_half');
      expect(
        ShapeBuilderActivity.shapeClassOf('asset:shape_square_blue') ==
            ShapeBuilderActivity.shapeClassOf('asset:shape_rect_blue'),
        isFalse,
      );
    });

    testWidgets(
      'on the rocket a red triangle dropped on a fin is right, and the three triangles are one sprite',
      (WidgetTester tester) async {
        final ShapeBuilderActivity rocket = content.activities['shp.build.rocket']! as ShapeBuilderActivity;
        final Set<String> triangles = <String>{
          for (final ShapeSlot s in rocket.slots)
            if (s.sprite.contains('triangle')) s.sprite,
        };
        expect(triangles, <String>{'asset:shape_triangle_red'});
        final LessonController c = LessonController(
          content: content,
          lesson: content.lessons['build-with-shapes']!,
          profileId: 'p-1',
          clock: FixedClock(1793000000000),
          record: (AttemptRecord r) async => written.add(r),
        );
        final ShapeBuilderSession s = ShapeBuilderSession(c, rocket);
        await hostSession(tester, s);
        final ShapeSlot fin = rocket.slots.lastWhere((ShapeSlot x) => x.sprite.contains('triangle'));
        final int piece = s.pieces.indexWhere((String p) => p.contains('triangle'));
        await s.drop(piece, fin.id);
        expect(s.filled, contains(fin.id));
        expect(written, isEmpty);
      },
    );

    test('a decoy and a rectangle in a square\'s place record the tag the item gives them, the answer\'s own otherwise', () {
      final ShapeBuilderActivity a = content.activities['shp.match.square']! as ShapeBuilderActivity;
      expect(a.pieceTags, isNotEmpty);
      for (final PieceTag t in a.pieceTags) {
        final ShapeSlot any = a.slots.first;
        expect(
          a.tagFor(
            t.piece,
            a.slots.firstWhere((ShapeSlot s) => t.slot == null || s.sprite == t.slot, orElse: () => any),
          ),
          t.tag,
        );
      }
      expect(a.engineTags, containsAll(a.pieceTags.map((PieceTag t) => t.tag)));
    });
  });
}
