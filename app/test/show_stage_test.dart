import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/show_stage.dart';
import 'package:nitznutz/play/sort_drag_session.dart';

import 'support/arc.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The host's hand in a Show (M11 Stage 2, docs/design/m11-rooms.md section 13): the outlines, the pointer's direction, and the lift, the trace
/// and the lit sides on the stage of a sort. The pictures are the design's; here only the geometry and the order of what is drawn are checked.
void main() {
  late PackContent content;
  late ShowArt art;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
    art = await ShowArt.load();
  });

  test('every picture of every Show of Shape Forest that a motion acts on has an outline', () {
    for (final Activity a in content.activities.values.where((Activity a) => a.isShow)) {
      for (final ShowStep s in a.show!.steps) {
        if (!ShowDirector.motions.contains(s.motion)) continue;
        final String? sprite = a is SortDragActivity
            ? a.items.firstWhere((SortItem i) => i.id == s.item).sprite
            : (a as ShapeBuilderActivity).slots.firstWhere((ShapeSlot x) => x.id == s.slot).sprite;
        expect(art.of(sprite!), isNotNull, reason: '${a.id} ${s.item ?? s.slot} $sprite');
      }
    }
  });

  test('the outlines: a polygon has one side for each corner, an open figure leaves a gap, a dome has a curve and a foot, a line is parsed', () {
    final ShowOutline triangle = art.of('asset:shape_triangle')!;
    expect(triangle.sides, hasLength(3));
    expect(triangle.gap, isNull);
    final ShowOutline open = art.of('asset:shape_open')!;
    expect(open.gap, isNotNull);
    expect(open.sides, hasLength(3));
    expect(art.of('asset:shape_curved')!.sides, hasLength(2));
    expect(art.of('asset:shape_circle')!.sides.single.length, greaterThan(20));
    // a coloured twin is its base
    expect(art.of('asset:shape_triangle_red')!.sides, hasLength(3));
    expect(parsePath('M10 50 L90 50'), <Offset>[const Offset(10, 50), const Offset(90, 50)]);
    expect(parsePath('M12 80 C 30 10, 70 10, 88 80')!.last, const Offset(88, 80));
    expect(parsePath('M0 0 Q 1 1 2 2'), isNull);
  });

  test('the pointer points away from the middle of the thing and stays in the design\'s range', () {
    const Offset middle = Offset(100, 100);
    expect(ShowDirector.angleAway(const Offset(100, 160), middle), closeTo(0, 1e-9));
    for (final Offset tip in const <Offset>[
      Offset(100, 40),
      Offset(40, 100),
      Offset(160, 100),
      Offset(60, 60),
      Offset(140, 140),
    ]) {
      final double a = ShowDirector.angleAway(tip, middle);
      expect(a, inInclusiveRange(-120 * 3.14159265 / 180 - 1e-6, 45 * 3.14159265 / 180 + 1e-6));
    }
  });

  test('the files of the show art are in the bundle declared by the pubspec', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/art/show/'));
    expect(pubspec, contains('assets/art/hosts/'));
    for (final String f in <String>['ant_a', 'ant_b', 'sand_tray', 'turn_front', 'rotate_cw']) {
      expect(File('assets/art/show/$f.svg').existsSync(), isTrue, reason: f);
    }
  });

  testWidgets(
    'a sort Show with the host\'s hand: the card is lifted to the middle under a veil, its sides are traced and stay lit, then it goes to its bin',
    (WidgetTester tester) async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = arcController(
        content,
        'any-shape',
        planOf(content, 'any-shape', PresentationStage.p4, newChild),
        written,
      );
      final SortDragSession s = SortDragSession(c, c.current as SortDragActivity)
        ..showStyle = ShowStyle(
          art: art,
          deep: TokenColors.domainShapesDeep,
          lip: TokenColors.domainShapesDeep,
        );
      await hostSession(tester, s);
      s.startHost();
      bool lifted = false;
      bool traced = false;
      bool veiled = false;
      for (int t = 0; t < 400; t++) {
        await tester.pump(const Duration(milliseconds: 100));
        lifted |= s.showMarks.spot != null;
        veiled |= s.showMarks.veil > 0.9;
        traced |= s.showMarks.lit.isNotEmpty && s.showMarks.tip != null;
        if (!s.hosting) break;
      }
      expect(lifted, isTrue);
      expect(veiled, isTrue);
      expect(traced, isTrue);
      expect(s.hosting, isFalse);
      // every mark and the veil are gone when the child's turn comes, and the host's cards are in their bins
      expect(s.showMarks.active, isFalse);
      expect(s.placed.length, s.activity.items.length - 1);
      expect(written, isEmpty);
      s.dispose();
    },
  );

  testWidgets('reduce motion: the lifted card appears in place and each side lights in turn', (
    WidgetTester tester,
  ) async {
    final List<AttemptRecord> written = <AttemptRecord>[];
    final LessonController c = arcController(
      content,
      'any-shape',
      planOf(content, 'any-shape', PresentationStage.p4, newChild),
      written,
    );
    final SortDragSession s = SortDragSession(c, c.current as SortDragActivity)
      ..showStyle = ShowStyle(
        art: art,
        deep: TokenColors.domainShapesDeep,
        lip: TokenColors.domainShapesDeep,
        still: true,
      );
    await hostSession(tester, s);
    s.startHost();
    int mostLit = 0;
    for (int t = 0; t < 400 && (s.hosting || t < 5); t++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (s.showMarks.lit.length > mostLit) mostLit = s.showMarks.lit.length;
      if (s.showMarks.tip != null) fail('a pointer glides although motion is reduced');
    }
    expect(mostLit, greaterThan(0));
    expect(s.hosting, isFalse);
    s.dispose();
  });
}
