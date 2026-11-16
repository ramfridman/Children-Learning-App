import 'package:flutter/gestures.dart' show HitTestEntry, HitTestResult;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/play/lesson_arc.dart' show ArcPart;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/show_solids.dart';
import 'package:nitznutz/play/show_stage.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/stroke_geometry.dart';
import 'package:nitznutz/play/trace_session.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';

import 'support/arc.dart';
import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The host's hand with the solids, the sand, the turn arrow of a piece and the tracing (M11 Stage 2, QA-4, docs/design/m11-rooms.md section 13.3):
/// what each motion draws, in what order, that every Show ends with the child's step left and nothing written, and that reduced movement shows the
/// end states with no travelling pointer. By ids and structure; the pictures are the design's (the goldens look at them).
void main() {
  late PackContent content;
  late ShowArt art;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack(
      edit: (Map<String, Object?> docs) {
        // the tracing lessons play the tracing Show once the pack has it as theirs (the curriculum-expert's `showWhenTraceLeads`)
        for (final String id in <String>['trace-the-shapes', 'draw-the-shapes']) {
          final Map<String, Object?> parts =
              (docs['lesson.$id.json']! as Map<String, Object?>)['parts']! as Map<String, Object?>;
          parts['show'] = 'show.shp-a-02.trace';
        }
        // the Show of the builder has no turned place among the host's steps: the second place is turned a quarter, to try the turn arrow
        // two halves of a square stand in ONE box (the second turned half a turn): the square the skill's own example makes
        final List<Object?> halves =
            ((docs['activity.b.shpb06.3.json']! as Map<String, Object?>)['scene']!
                    as Map<String, Object?>)['slots']!
                as List<Object?>;
        for (final (int i, Object? h) in halves.indexed) {
          (h! as Map<String, Object?>)
            ..['x'] = 0.0
            ..['y'] = 0.0
            ..['w'] = 1.0
            ..['h'] = 1.0
            ..['rot'] = i == 0 ? 0 : 180;
        }
        final Map<String, Object?> builder = docs['activity.show.shp-a-06.json']! as Map<String, Object?>;
        (((builder['scene']! as Map<String, Object?>)['slots']! as List<Object?>)[1]!
                as Map<String, Object?>)['rot'] =
            90;
      },
    );
    art = await ShowArt.load();
  });

  ShowStyle style({bool still = false, bool slow = false}) => ShowStyle(
    art: art,
    deep: TokenColors.domainShapesDeep,
    lip: TokenColors.domainShapesDeep,
    still: still,
    slow: slow,
  );

  /// Runs the host's part of the Show of [lessonId] and calls [seen] with the marks every 100 ms; returns the session, still alive.
  Future<SortDragSession> runSort(
    WidgetTester tester,
    String lessonId, {
    bool still = false,
    bool slow = false,
    required void Function(ShowMarks m, SortDragSession s) seen,
  }) async {
    final List<AttemptRecord> written = <AttemptRecord>[];
    final LessonController c = arcController(
      content,
      lessonId,
      planOf(content, lessonId, PresentationStage.p4, newChild),
      written,
    );
    final SortDragSession s = SortDragSession(c, c.current as SortDragActivity)
      ..showStyle = style(still: still, slow: slow);
    await hostSession(tester, s);
    s.startHost();
    for (int t = 0; t < 600 && (s.hosting || t < 5); t++) {
      await tester.pump(const Duration(milliseconds: 100));
      seen(s.showMarks, s);
    }
    expect(s.hosting, isFalse, reason: '$lessonId: the host is done');
    expect(s.showMarks.active, isFalse, reason: 'every mark is gone when the child\'s turn comes');
    expect(s.placed.length, s.activity.items.length - 1, reason: 'the host\'s cards are in their bins');
    expect(written, isEmpty);
    return s;
  }

  testWidgets(
    'push: the pointer stands behind the ball and presses, the ball rolls turning with speed lines, and the block stacks with a squash',
    (WidgetTester tester) async {
      bool pressed = false, rolled = false, lines = false, squashed = false;
      double mostTurn = 0;
      final SortDragSession s = await runSort(
        tester,
        'roll-or-stack',
        seen: (ShowMarks m, SortDragSession s) {
          pressed |= m.pressAt != null && m.tip != null;
          lines |= m.speed.length == 3 && m.speedAlpha > 0;
          if (m.spotTurn.abs() > mostTurn) mostTurn = m.spotTurn.abs();
          rolled |=
              m.spot != null &&
              m.spot!.width < ShowDirector.spotSide(const Size(330, 128)) - 5 &&
              m.speed.isNotEmpty;
          squashed |= m.spotSquash < 0.99;
        },
      );
      expect(pressed, isTrue, reason: 'a press with its ring');
      expect(lines, isTrue, reason: 'three speed lines behind the ball');
      expect(rolled, isTrue);
      expect(
        mostTurn,
        greaterThan(1),
        reason: 'a ball that rolls to its bin turns more than a radian on the way',
      );
      expect(squashed, isTrue, reason: 'the stacked block settles with a squash');
      expect(s.placed.keys, containsAll(<String>['i1', 'i2']));
      s.dispose();
    },
  );

  testWidgets(
    'turn: the orbit arrow draws, sweeps twice while the solid sways about its base, and a cone\'s one point gets its ring',
    (WidgetTester tester) async {
      bool back = false, sweptFull = false, sway = false, ring = false;
      int sweeps = 0;
      double last = 0;
      final SortDragSession s = await runSort(
        tester,
        'solids',
        seen: (ShowMarks m, SortDragSession s) {
          back |= m.orbitBox != null && m.orbitBack > 0.99;
          if (m.orbitSweep < last - 0.5) sweeps++;
          last = m.orbitSweep;
          sweptFull |= m.orbitSweep > 0.99;
          sway |= m.turnAboutBase && m.spotTurn.abs() > 0.02;
          ring |= m.gap != null;
        },
      );
      expect(back, isTrue, reason: 'the dotted back half');
      expect(sweptFull, isTrue, reason: 'the front half sweeps all the way');
      expect(
        sweeps,
        greaterThanOrEqualTo(1),
        reason: 'and starts again for a second sweep (the first sweep of each solid, then the next)',
      );
      expect(sway, isTrue, reason: 'it sways about its base, 4 degrees');
      expect(ring, isTrue, reason: 'a cone has one point');
      s.dispose();
    },
  );

  testWidgets(
    'stamp: the tray rises, the solid presses and lifts aside, the print stays and is traced, grains puff',
    (WidgetTester tester) async {
      bool tray = false, print = false, traced = false, grains = false, aside = false;
      final SortDragSession s = await runSort(
        tester,
        'solid-and-face',
        seen: (ShowMarks m, SortDragSession s) {
          tray |= m.tray != null && m.trayRise > 0.99;
          print |= m.printAlpha > 0.99 && m.printSvg != null;
          traced |= m.lit.isNotEmpty && m.printSvg != null;
          grains |= m.grains.isNotEmpty;
          aside |= m.tray != null && m.spot != null && m.spot!.center.dx < m.tray!.center.dx - 10;
        },
      );
      expect(tray, isTrue);
      expect(print, isTrue, reason: 'the print fades in as the solid lifts');
      expect(traced, isTrue, reason: 'its outline is traced and stays lit');
      expect(grains, isTrue);
      expect(aside, isTrue, reason: 'the solid moves aside, toward the end (left) side, so the print shows');
      s.dispose();
    },
  );

  testWidgets('reduce motion: the end states, in order, and the pointer never travels', (
    WidgetTester tester,
  ) async {
    for (final String lesson in <String>['roll-or-stack', 'solids', 'solid-and-face']) {
      bool travelled = false, ended = false;
      final SortDragSession s = await runSort(
        tester,
        lesson,
        still: true,
        seen: (ShowMarks m, SortDragSession s) {
          // the pointer never glides: when it is drawn it is where it presses, and the tray and the arrow appear as they are
          travelled |= m.tip != null && m.pressAt == null && m.tipAngle != 0 && m.drawing.length > 1;
          ended |= m.orbitSweep == 1 || m.printAlpha == 1 || m.spot?.width == 40;
        },
      );
      expect(travelled, isFalse, reason: lesson);
      expect(ended, isTrue, reason: '$lesson shows an end state');
      s.dispose();
    }
  });

  test('the leg points away from the middle, and where away is outside its range it takes the nearest end round the circle', () {
    const Offset middle = Offset(100, 100);
    // above the middle: -120 degrees (in from the host's side), not +45 (across the shape)
    expect(ShowDirector.angleAway(const Offset(100, 40), middle), closeTo(-120 * 3.14159265 / 180, 1e-6));
    // the lower left of the middle: the leg goes down and to the left
    expect(ShowDirector.angleAway(const Offset(60, 140), middle), closeTo(45 * 3.14159265 / 180, 1e-6));
    // at the upper left it is the nearer end that is taken (+45), and it never lies across
    final double upperLeft = ShowDirector.angleAway(const Offset(60, 60), middle);
    expect(upperLeft, closeTo(45 * 3.14159265 / 180, 1e-6));
    // every direction stays in the range
    for (int d = 0; d < 360; d += 15) {
      final double a = ShowDirector.angleAway(
        middle + Offset.fromDirection(d * 3.14159265 / 180, 60),
        middle,
      );
      expect(a, inInclusiveRange(-120 * 3.14159265 / 180 - 1e-6, 45 * 3.14159265 / 180 + 1e-6));
    }
  });

  test('a tip near the top of the stage holds the leg level, so that it is not cut off by the top edge', () {
    const Offset middle = Offset(165, 64);
    const Offset hole = Offset(150, 14);
    expect(ShowDirector.angleAway(hole, middle), lessThan(-1.5));
    expect(ShowDirector.angleAway(hole, middle, above: hole.dy), closeTo(-3.14159265 / 2, 1e-6));
    // with room above it the leg is as it was
    expect(
      ShowDirector.angleAway(const Offset(150, 90), middle, above: 90),
      ShowDirector.angleAway(const Offset(150, 90), middle),
    );
  });

  test('the print of a solid by the kind of its face, and what rolls', () {
    expect(printKindOf('asset:solid_cylinder'), 'circle');
    expect(printKindOf('asset:solid_cone'), 'circle');
    expect(printKindOf('asset:can'), 'circle');
    expect(printKindOf('asset:party_hat'), 'circle');
    expect(printKindOf('asset:gift_box'), 'rect');
    expect(printKindOf('asset:solid_box'), 'rect');
    expect(printKindOf('asset:dice'), 'square');
    expect(printKindOf('asset:pyramid_egypt'), 'square');
    expect(printKindOf('asset:solid_pyramid'), 'square');
    expect(printKindOf('asset:solid_pyramid', detail: 'side'), 'triangle');
    expect(printKindOf('asset:ball_red'), isNull);
    expect(rollsLike('asset:ball_blue'), isTrue);
    expect(rollsLike('asset:solid_sphere'), isTrue);
    expect(rollsLike('asset:block'), isFalse);
  });

  test('the solids of the outlines: a cone has a point, a cylinder two circles, a box a face', () {
    expect(art.solidOf('asset:solid_cone')!.point, isNotNull);
    expect(art.solidOf('asset:solid_cylinder')!.top, hasLength(4));
    expect(art.solidOf('asset:solid_cylinder')!.base, hasLength(4));
    expect(art.solidOf('asset:solid_box')!.face, hasLength(4));
    expect(art.solidOf('asset:ball_red'), isNull);
    expect(art.prints.keys, containsAll(<String>['circle', 'rect', 'square', 'triangle']));
  });

  test('the right triangle has its own ghost: the half of a square is not the triangle', () {
    expect(ShapeBuilderSession.ghostKindOf('asset:shape_triangle_half'), GhostKind.rightTriangle);
    expect(ShapeBuilderSession.ghostKindOf('asset:shape_triangle_half_red'), GhostKind.rightTriangle);
    expect(ShapeBuilderSession.ghostKindOf('asset:shape_triangle_red'), GhostKind.triangle);
  });

  testWidgets(
    'a place that is turned in the picture shows its piece turning under the turn arrow, then the piece is in its place',
    (WidgetTester tester) async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = arcController(
        content,
        'build-with-shapes',
        planOf(content, 'build-with-shapes', PresentationStage.p4, newChild),
        written,
      );
      final ShapeBuilderSession s = ShapeBuilderSession(c, c.current as ShapeBuilderActivity)
        ..showStyle = style();
      await hostSession(tester, s);
      s.startHost();
      bool arrow = false, turning = false, clockwise = false;
      double most = 0;
      for (int t = 0; t < 600 && (s.hosting || t < 5); t++) {
        await tester.pump(const Duration(milliseconds: 100));
        final ShowMarks m = s.showMarks;
        arrow |= m.rotateBox != null;
        clockwise |= m.rotateBox != null && m.rotateClockwise;
        if (m.rotateBox != null && m.spotTurn.abs() > most) most = m.spotTurn.abs();
        turning |= m.rotateBox != null && m.spotTurn.abs() > 0.1 && m.spotTurn.abs() < 1.5;
      }
      expect(s.hosting, isFalse);
      expect(arrow, isTrue, reason: 'the turn arrow round the piece');
      expect(
        clockwise,
        isTrue,
        reason: 'the shape-friends builder\'s turned place is turned clockwise (90 degrees)',
      );
      expect(turning, isTrue, reason: 'the piece turns on its way, it does not jump');
      expect(
        most,
        inInclusiveRange(1.3, 3.14159265 / 2 + 0.01),
        reason: 'the piece reaches the quarter turn',
      );
      expect(s.showMarks.active, isFalse);
      expect(written, isEmpty);
      s.dispose();
    },
  );

  testWidgets(
    'the tracing Show: the host draws every side but the last, each stays lit, the child traces the last and nothing is written',
    (WidgetTester tester) async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = arcController(
        content,
        'trace-the-shapes',
        planOf(content, 'trace-the-shapes', PresentationStage.p4, newChild),
        written,
      );
      final TraceActivity show = c.current as TraceActivity;
      expect(show.isShow, isTrue);
      final TraceSession s = TraceSession(c, show)..showStyle = style();
      await hostSession(tester, s);
      s.startHost();
      int mostLit = 0;
      bool pointer = false;
      for (int t = 0; t < 600 && (s.hosting || t < 5); t++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (s.showMarks.lit.length > mostLit) mostLit = s.showMarks.lit.length;
        pointer |= s.showMarks.tip != null;
      }
      expect(s.hosting, isFalse);
      expect(pointer, isTrue);
      expect(mostLit, show.show!.hostSteps.length, reason: 'one lit side for each host step, staying lit');
      expect(s.childStrokes, hasLength(1));
      // the child has the rest of the stroke: from where the host stopped to the end
      final List<Offset> stroke = show.strokes.single;
      expect(s.childStrokes.single.first, stroke[show.show!.hostSteps.length]);
      expect(s.childStrokes.single.last, stroke.last);
      // a wrong stroke is only "let's look again": nothing is written and the child may try again
      s.begin(const Offset(5, 5));
      s.extend(const Offset(10, 10));
      s.extend(const Offset(12, 14));
      await s.end();
      await tester.pump(const Duration(milliseconds: 100));
      expect(written, isEmpty);
      expect(c.solved, isFalse);
      // the right stroke finishes the Show
      final List<Offset> want = s.childStrokes.single;
      s.begin(want.first);
      for (final Offset p in denseStroke(want)) {
        s.extend(p);
      }
      await s.end();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.solved, isTrue);
      expect(written, isEmpty, reason: 'a Show writes nothing');
      await tester.pump(const Duration(seconds: 3));
      s.dispose();
    },
  );

  testWidgets(
    'a tracing in Together: the host draws its first side and the child traces the rest, from where the host stopped',
    (WidgetTester tester) async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = arcController(
        content,
        'trace-the-shapes',
        planOf(content, 'trace-the-shapes', PresentationStage.p4, newChild),
        written,
      );
      goTo(c, ArcPart.together);
      final TraceActivity item = c.current as TraceActivity;
      expect(c.step!.lead, 1);
      final TraceSession s = TraceSession(c, item)..showStyle = style();
      await hostSession(tester, s);
      s.startHost();
      for (int t = 0; t < 600 && (s.hosting || t < 5); t++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(s.hosting, isFalse);
      expect(s.showMarks.lit, hasLength(1));
      expect(s.childStrokes, isNotEmpty);
      expect(
        s.childStrokes.first.first,
        isNot(item.strokes.first.first),
        reason: 'the child starts where the host stopped',
      );
      expect(written, isEmpty);
      s.dispose();
    },
  );

  testWidgets(
    'two halves of a square in one box: a touch on the first half is not caught by the second (the touch is on the triangle itself)',
    (WidgetTester tester) async {
      final ShapeBuilderActivity a = content.activities['b.shpb06.3']! as ShapeBuilderActivity;
      final LessonController c = LessonController(
        content: content,
        lesson: Lesson.mission(
          id: 'qa',
          itemIds: <String>[a.id],
          skillIds: <String>[a.skillId],
          celebration: const Spoken(vo: 'vo:x', caption: 'x'),
        ),
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async {},
      );
      final ShapeBuilderSession s = ShapeBuilderSession(c, a);
      await hostSession(tester, s);
      final Rect first = tester.getRect(find.byKey(const Key('slot-s1')));
      final Rect second = tester.getRect(find.byKey(const Key('slot-s2')));
      // (the rects are those of the places' touch boxes)
      // the two halves stand in one box: a touch is the half's if it is on the half's triangle, whichever is on top
      final Rect box = first;
      bool onlyFirst = false, onlySecond = false;
      for (double x = box.left + 2; x < box.right; x += 3) {
        for (double y = box.top + 2; y < box.bottom; y += 3) {
          final HitTestResult hit = HitTestResult();
          tester.binding.hitTestInView(hit, Offset(x, y), tester.view.viewId);
          final Iterable<RenderObject> path = hit.path
              .map((HitTestEntry e) => e.target)
              .whereType<RenderObject>();
          bool reaches(String id) =>
              find.byKey(Key('slot-$id')).evaluate().any((Element e) => path.contains(e.renderObject));
          onlyFirst |= reaches('s1') && !reaches('s2');
          onlySecond |= reaches('s2') && !reaches('s1');
        }
      }
      expect((second.center - first.center).distance, lessThan(1), reason: 'one box for both places');
      expect(
        onlyFirst,
        isTrue,
        reason: 'the first half has a touch the second does not catch (the second is on top of it)',
      );
      expect(onlySecond, isTrue, reason: 'and the second has its own');
      s.dispose();
    },
  );

  testWidgets('the count bins of the sides stand as tallies, not as flat dashes', (
    WidgetTester tester,
  ) async {
    final SortDragActivity a = content.activities.values.whereType<SortDragActivity>().firstWhere(
      (SortDragActivity a) => a.bins.any((SortBin b) => b.sprite == 'asset:stick_long' && b.count > 1),
    );
    final LessonController c = LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'qa',
        itemIds: <String>[a.id],
        skillIds: <String>[a.skillId],
        celebration: const Spoken(vo: 'vo:x', caption: 'x'),
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
    );
    final SortDragSession s = SortDragSession(c, a);
    await hostSession(tester, s);
    final Finder tally = find.byKey(const Key('bin-tally'));
    expect(tally, findsWidgets);
    for (final Element e in tally.evaluate()) {
      final Size size = (e.renderObject! as RenderBox).size;
      expect(
        size.height,
        greaterThan(size.width * 0.5),
        reason: 'sticks that stand are taller than they are wide',
      );
      expect(size.height, greaterThan(30));
    }
    s.dispose();
  });
}
