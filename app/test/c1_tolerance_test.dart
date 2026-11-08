// M10 X5 (2026-11-07): a number line placed by estimate. `answer.tolerance` makes a touch within that many of the target right, and
// `scene.tickStep` draws a tick only at every nth number (a line of 0 to 100 with ticks of ten). The model, the validator, the line and
// the way the guide counts along it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/number_line_session.dart';

import 'support/c1_screens.dart';
import 'support/fakes.dart';
import 'support/harness.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

/// Item c.numc06.1 as a line of 0 to 100 with ticks of ten, ends labelled, 70 to be placed within 8.
void _estimate(Map<String, Object?> docs) {
  final Map<String, Object?> d = _m(docs['activity.c.numc06.1.json']);
  d['templateVersion'] = '1.1';
  d['scene'] = <String, Object?>{
    'background': 'asset:meadow',
    'from': 0,
    'to': 100,
    'tickStep': 10,
    'markerSprite': 'asset:frog',
    'labels': <Object?>[0, 100],
  };
  d['answer'] = <String, Object?>{
    'type': 'line',
    'mode': 'place',
    'target': 70,
    'tolerance': 8,
    'misconception': 'M-PV-FACE',
    'mirrorMisconception': 'M-NL-DIR',
  };
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack(edit: _estimate);
  });

  test('the model reads the tolerance and the tick step; no tolerance means the exact tick', () {
    final NumberLineActivity a = content.activities['c.numc06.1']! as NumberLineActivity;
    expect((a.tolerance, a.tickStep, a.target), (8, 10, 70));
    expect(
      <bool>[
        for (final int n in <int>[61, 62, 70, 78, 79]) a.isRight(n),
      ],
      <bool>[false, true, true, true, false],
    );
    final NumberLineActivity plain = content.activities['c.numc06.2']! as NumberLineActivity;
    expect((plain.tolerance, plain.tickStep), (0, 1));
    expect(plain.isRight(plain.target), isTrue);
    expect(plain.isRight(plain.target + 1), isFalse);
  });

  group('the validator', () {
    Future<List<String>> problemsOf(
      void Function(Map<String, Object?> scene, Map<String, Object?> answer, Map<String, Object?> doc) edit,
    ) async {
      final VerifiedPack pack = await loadSourceVerified();
      _estimate(pack.docs);
      _m(pack.manifest['templates'])['number_line'] = '1.1';
      final Map<String, Object?> d = _m(pack.docs['activity.c.numc06.1.json']);
      edit(_m(d['scene']), _m(d['answer']), d);
      return <String>[
        for (final Problem x in validatePack(
          manifest: pack.manifest,
          docs: pack.docs,
          files: pack.files.keys.toSet(),
        ))
          if (x.path.startsWith('activity.c.numc06.1.json')) x.toString(),
      ];
    }

    test('a good estimate item is taken', () async {
      expect(await problemsOf((_, _, _) {}), isEmpty);
    });

    test('a step that does not end on a tick, a tolerance as wide as the line or on a jump, a mirror inside it and an old version are refused', () async {
      expect(await problemsOf((Map<String, Object?> s, _, _) => s['tickStep'] = 30), isNotEmpty);
      expect(await problemsOf((_, Map<String, Object?> a, _) => a['tolerance'] = 100), isNotEmpty);
      expect(
        await problemsOf((_, Map<String, Object?> a, _) => a['target'] = 50),
        isNotEmpty,
        reason: 'the mirror of the answer is inside the tolerance',
      );
      expect(await problemsOf((_, _, Map<String, Object?> d) => d['templateVersion'] = '1.0'), isNotEmpty);
      expect(
        await problemsOf((Map<String, Object?> s, Map<String, Object?> a, _) {
          a['mode'] = 'jump';
          s['start'] = 10;
          s['hops'] = <Object?>[60];
        }),
        isNotEmpty,
      );
    });
  });

  group('the line', () {
    final List<AttemptRecord> written = <AttemptRecord>[];
    late LessonController c;
    late NumberLineActivity a;

    Future<NumberLineSession> start(WidgetTester t) async {
      written.clear();
      c = LessonController(
        content: content,
        lesson: Lesson.mission(
          id: 'one',
          itemIds: <String>['c.numc06.1'],
          skillIds: <String>['NUM-C-06'],
          celebration: content.lessons['butterflies']!.celebration,
        ),
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async => written.add(r),
      );
      a = c.current as NumberLineActivity;
      final NumberLineSession s = NumberLineSession(c, a);
      const ActivitySpec spec = ActivitySpec.phone;
      await t.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (BuildContext ctx) => Center(
                  child: SizedBox(
                    width: spec.stage.width,
                    height: spec.stage.height,
                    child: s.buildStage(ctx, spec.stage.size, spec),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return s;
    }

    Offset onTick(WidgetTester t, int n) {
      final Rect r = t.getRect(find.byKey(const Key('line-touch')));
      return Offset(r.left + 22 + (n - a.from) / (a.to - a.from) * (r.width - 44), r.center.dy);
    }

    testWidgets(
      'ticks stand every ten, a touch within eight of 70 is right, another is not yet with its tag',
      (WidgetTester t) async {
        final NumberLineSession s = await start(t);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('100'), findsOneWidget);
        // 11 ticks of ten (0 to 100), not 101.
        final int ticks = find
            .descendant(of: find.byKey(const Key('line-stage')), matching: find.byType(Column))
            .evaluate()
            .length;
        expect(ticks, 11);
        await t.tapAt(onTick(t, 30));
        await t.pump(const Duration(milliseconds: 60));
        expect((written.last.result, written.last.misconceptionTag), ('incorrect', 'M-NL-DIR'));
        await t.pump(const Duration(milliseconds: 1500));
        await t.tapAt(onTick(t, 7));
        await t.pump(const Duration(milliseconds: 60));
        expect((written.last.result, written.last.misconceptionTag), ('incorrect', 'M-PV-FACE'));
        await t.pump(const Duration(milliseconds: 1500));
        await t.tapAt(onTick(t, 64));
        await t.pump(const Duration(milliseconds: 60));
        expect((written.last.result, written.last.response), ('correct', '64'));
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'the guide counts along the line by tens, ending on 70, and a touch within the tolerance then ends it',
      (WidgetTester t) async {
        final NumberLineSession s = await start(t);
        for (int k = 0; k < a.maxAttempts; k++) {
          await t.tapAt(onTick(t, 7));
          await t.pump(const Duration(milliseconds: 60));
          await t.pump(const Duration(milliseconds: 1500));
        }
        expect(c.guided, isTrue);
        await t.pump(const Duration(seconds: 8));
        expect(s.demoRunning, isFalse);
        await t.tapAt(onTick(t, 72));
        await t.pump(const Duration(milliseconds: 60));
        expect(
          written.last.result,
          'correct',
          reason: 'within the tolerance, the answer is taken after the guide',
        );
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );
  });
}
