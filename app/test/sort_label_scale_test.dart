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

/// QA-1: the label of a bin keeps its room when the text is larger. The strip over a bin's sample is 17 points for a text of 13, which is 1.3 times
/// the text as drawn; at the system's text size 1.3 the text is 16.9 and the strip stayed 17, so the top of the letters was cut (and, with niqqud,
/// more). QA's first test compared the strip with the 1.7 line box of the text (22 at 1.0), which no strip of the design can hold and which is not
/// what is cut: the letters' ink sits inside the box with even leading. The measure here is the ink: a strip must be at least 1.3 times the text
/// as it is drawn (its font times the scaler), which is exactly what the design gives at 1.0, and the label must not be cut to an ellipsis.
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

  Future<List<({String id, double strip, double drawn, bool cut})>> labelsOf(
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
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: spec.stage.size,
                child: Builder(builder: (BuildContext ctx) => s.buildStage(ctx, spec.stage.size, spec)),
              ),
            ),
          ),
        ),
      ),
    );
    final List<({String id, double strip, double drawn, bool cut})> out =
        <({String id, double strip, double drawn, bool cut})>[];
    for (final SortBin b in a.bins) {
      final Finder text = find.byKey(Key('bin-label-${b.id}'));
      final RenderParagraph p = tester.renderObject<RenderParagraph>(text);
      final Text widget = tester.widget<Text>(text);
      final double font = widget.style!.fontSize! * widget.textScaler!.scale(1);
      out.add((
        id: b.id,
        strip: tester.getSize(find.byKey(Key('bin-strip-${b.id}'))).height,
        drawn: font,
        cut: p.didExceedMaxLines,
      ));
    }
    s.dispose();
    return out;
  }

  final Map<String, ActivitySpec> boards = <String, ActivitySpec>{
    'phone': ActivitySpec.phone,
    'phoneSE': ActivitySpec.phoneSE,
  };

  for (final MapEntry<String, ActivitySpec> board in boards.entries) {
    testWidgets(
      'every bin label of every sort on the ${board.key} has the room of its ink at 1.0, 1.15 and 1.3',
      (WidgetTester tester) async {
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
          double? stripAt1;
          for (final double scale in <double>[1.0, 1.15, 1.3]) {
            final labels = await labelsOf(tester, a, board.value, scale);
            for (final l in labels) {
              checked++;
              if (l.strip < 1.3 * l.drawn - 0.01) {
                bad.add('${a.id}/${l.id} at $scale: strip ${l.strip} for text ${l.drawn}');
              }
              if (l.cut) bad.add('${a.id}/${l.id} at $scale: the label is cut to an ellipsis');
            }
            stripAt1 ??= labels.first.strip;
            if (scale > 1) {
              if (labels.first.strip > stripAt1) grew++;
              expect(
                labels.first.strip,
                greaterThanOrEqualTo(stripAt1),
                reason: '${a.id}: the strip never shrinks with the text at $scale',
              );
            }
          }
        }
        expect(bad, isEmpty, reason: bad.take(8).join('\n'));
        expect(checked, greaterThan(300));
        expect(grew, greaterThan(40), reason: 'most labels fit one line at 1.3, so most strips grow');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }

  testWidgets(
    'the arithmetic discriminates: a strip of the old 17 fails the ink test at 1.3 and passes at 1.0',
    (WidgetTester tester) async {
      expect(17 < 1.3 * (13 * 1.3), isTrue);
      expect(17 < 1.3 * (13 * 1.0), isFalse);
    },
  );
}
