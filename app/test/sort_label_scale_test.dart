import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/sort_drag_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The label of a bin (docs/design/m11/min-sizes.md R6): 18 points on a phone and 24 on a tablet, weight 500, line height 1.7, grown with the
/// system's text size (up to 1.3) where its box lets it and kept at its own size, never smaller, where it does not; and never cut to an
/// ellipsis (QA-1), on every board and at 1.0, 1.15 and 1.3.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  Lesson one(Activity a) => Lesson.mission(
    id: 'qa',
    itemIds: <String>[a.id],
    skillIds: <String>[a.skillId],
    celebration: const Spoken(vo: 'vo:x', caption: 'x'),
  );

  Future<List<({String id, double drawn, bool cut, FontWeight? weight, double? height})>> labelsOf(
    WidgetTester tester,
    SortDragActivity a,
    ActivitySpec board,
    double scale,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final LessonController c = LessonController(
      content: content,
      lesson: one(a),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
    );
    final SortDragSession s = SortDragSession(c, a);
    final ActivitySpec spec = s.layoutFor(board);
    final Size size = spec.stageIsCard
        ? Size(spec.stage.width - 32, spec.stage.height - 32)
        : spec.stage.size;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: size,
                child: Builder(builder: (BuildContext ctx) => s.buildStage(ctx, size, spec)),
              ),
            ),
          ),
        ),
      ),
    );
    final List<({String id, double drawn, bool cut, FontWeight? weight, double? height})> out =
        <({String id, double drawn, bool cut, FontWeight? weight, double? height})>[];
    for (final SortBin b in a.bins) {
      final Finder text = find.byKey(Key('bin-label-${b.id}'));
      final RenderParagraph p = tester.renderObject<RenderParagraph>(text);
      final Text widget = tester.widget<Text>(text);
      out.add((
        id: b.id,
        drawn: widget.style!.fontSize! * widget.textScaler!.scale(1),
        cut: p.didExceedMaxLines,
        weight: widget.style!.fontWeight,
        height: widget.style!.height,
      ));
    }
    expect(tester.takeException(), isNull, reason: '${a.id}: the stage lays out without an overflow');
    s.dispose();
    return out;
  }

  final Map<String, ActivitySpec> boards = <String, ActivitySpec>{
    'phone': ActivitySpec.phone,
    'phoneSE': ActivitySpec.phoneSE,
    'tabletL': ActivitySpec.tabletLandscape,
    'tabletP': ActivitySpec.tabletPortrait,
  };

  for (final MapEntry<String, ActivitySpec> board in boards.entries) {
    testWidgets(
      'every bin label of every sort on the ${board.key} is 18 (24 on a tablet) at least, w500, line 1.7, and never cut, at 1.0, 1.15 and 1.3',
      (WidgetTester tester) async {
        final double base = board.key.startsWith('tablet') ? 24 : 18;
        final List<SortDragActivity> sorts = content.activities.values
            .whereType<SortDragActivity>()
            .where(
              (SortDragActivity a) =>
                  !a.isShow && !a.share && a.bins.every((SortBin b) => b.label.isNotEmpty),
            )
            .toList();
        expect(sorts.length, greaterThan(40));
        int checked = 0;
        int grew = 0;
        final List<String> bad = <String>[];
        for (final SortDragActivity a in sorts) {
          double? at1;
          for (final double scale in <double>[1.0, 1.15, 1.3]) {
            final labels = await labelsOf(tester, a, board.value, scale);
            for (final l in labels) {
              checked++;
              if (l.drawn < base - 0.01) bad.add('${a.id}/${l.id} at $scale: ${l.drawn} is under $base');
              if (l.weight != FontWeight.w500) bad.add('${a.id}/${l.id}: weight ${l.weight}');
              if (l.height != 1.7) bad.add('${a.id}/${l.id}: line height ${l.height}');
              if (l.cut) bad.add('${a.id}/${l.id} at $scale: the label is cut to an ellipsis');
            }
            at1 ??= labels.first.drawn;
            if (scale > 1) {
              if (labels.first.drawn > at1 + 0.01) grew++;
              expect(
                labels.first.drawn,
                greaterThanOrEqualTo(at1 - 0.01),
                reason: '${a.id}: the label never shrinks with the text at $scale',
              );
            }
          }
        }
        expect(bad, isEmpty, reason: bad.take(8).join('\n'));
        expect(checked, greaterThan(300));
        expect(grew, greaterThan(20), reason: 'most labels fit at 1.3, so most grow');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
