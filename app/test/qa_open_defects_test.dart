import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/play/trace_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// QA's open defects on `m9-content` (docs/qa/m9-baseline.md). Each test FAILS until its defect is fixed; it is the proof of
/// the fix. They are skipped in a normal run so that the suite stays green; run them with
///
///   flutter test --no-pub --dart-define=QA_OPEN=true test/qa_open_defects_test.dart
///
/// When a defect is fixed, the owner of the fix removes `skip: _open` from its test (it then runs in every build).
const bool _runOpen = bool.fromEnvironment('QA_OPEN');
const bool _open = !_runOpen;

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];

  LessonController start(String lessonId, int index) {
    written.clear();
    final LessonController c = LessonController(
      content: content,
      lesson: content.lessons[lessonId]!,
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async => written.add(r),
    );
    for (int i = 0; i < index; i++) {
      c.next();
    }
    return c;
  }

  /// The stage and the tiles as the phone's activity frame places them (the same host as drag_templates_test).
  Future<void> host(WidgetTester tester, TemplateSession s, {ActivitySpec spec = ActivitySpec.phone}) async {
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

  Future<void> pause(WidgetTester t) =>
      t.pump(TemplateSession.notYetPause + const Duration(milliseconds: 150));

  Future<void> stroke(TraceSession s, List<Offset> pts) async {
    s.begin(pts.first);
    for (final Offset p in pts.skip(1)) {
      s.extend(p);
    }
    await s.end();
  }

  testWidgets(
    'QA-1 trace: once the help is at its top, a wrong stroke is not written again (every other template keeps this rule)',
    (WidgetTester tester) async {
      final LessonController c = start('trace-numbers-0-4', 1); // x.numb07.2, the numeral one
      final TraceActivity a = c.current as TraceActivity;
      final TraceSession s = TraceSession(c, a);
      for (int k = 0; k < a.maxAttempts; k++) {
        await stroke(s, const <Offset>[Offset(1, 1), Offset(3, 2)]);
        await pause(tester);
      }
      expect(c.guided, isTrue);
      final int before = written.length;
      await stroke(s, const <Offset>[Offset(1, 1), Offset(3, 2)]);
      await pause(tester);
      expect(
        written.length,
        before,
        reason: 'M9 §14 rule 2: a wrong move is never counted twice once the help is at its top',
      );
      expect(c.errors, a.maxAttempts);
      s.dispose();
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'QA-2 trace: a finger on the painted start dot is read as the start of the path (the touch is not offset by the border)',
    (WidgetTester tester) async {
      final LessonController c = start('trace-numbers-0-4', 1);
      final TraceActivity a = c.current as TraceActivity;
      final TraceSession s = TraceSession(c, a);
      await host(tester, s);
      // Where the painter draws: the CustomPaint inside the bordered box.
      final Rect paint = tester.getRect(
        find.descendant(of: find.byKey(const Key('trace-stage')), matching: find.byType(CustomPaint)).first,
      );
      Offset painted(Offset unit) => paint.topLeft + unit * (paint.width / 100);
      final List<Offset> path = a.strokes.first;
      for (final Offset p in <Offset>[path.first, path.last]) {
        final TestGesture g = await tester.startGesture(painted(p));
        await tester.pump(const Duration(milliseconds: 16));
        await g.moveBy(const Offset(0, 1));
        await tester.pump(const Duration(milliseconds: 16));
        expect(s.current, isNotEmpty);
        expect(
          (s.current.first - p).distance,
          lessThan(1.0),
          reason: 'touch at the painted point $p was read as ${s.current.first} (box units)',
        );
        await g.cancel();
        // The cancelled touch ends a short stroke, which is a "not yet": the next touch is taken after its pause.
        await pause(tester);
        s.current = <Offset>[];
      }
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA-3 match pairs: a set of one is not drawn larger than the pictures of a set of three (M9 §13 fair-size rule)',
    (WidgetTester tester) async {
      final LessonController c = start('match-numbers-sets', 0); // x.numa07.1: 1, 2, 3 and sets of apples
      final MatchPairsActivity a = c.current as MatchPairsActivity;
      final MatchPairsSession s = MatchPairsSession(c, a);
      await host(tester, s);
      final MatchFace one = a.right.firstWhere((MatchFace f) => f.count == 1);
      final MatchFace three = a.right.firstWhere((MatchFace f) => f.count == 3);
      Size apple(MatchFace f) => tester.getSize(
        find.descendant(of: find.byKey(Key('bottom-${f.id}')), matching: find.byType(SvgPicture)).first,
      );
      final double single = apple(one).width;
      final double inThree = apple(three).width;
      expect(
        single,
        lessThanOrEqualTo(inThree * 1.25),
        reason:
            'one apple is ${single.toStringAsFixed(0)} pt wide, each apple of three ${inThree.toStringAsFixed(0)} pt',
      );
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA-4 shop on the phone: every coin put on the counter stays visible on the counter (so it can be taken back)',
    (WidgetTester tester) async {
      final LessonController c = start('pay-exactly', 1); // x.mathb17.2: seven coins in the purse
      final ShopPayActivity a = c.current as ShopPayActivity;
      final ShopPaySession s = ShopPaySession(c, a);
      await host(tester, s);
      for (final PurseCoin coin in List<PurseCoin>.of(s.purse)) {
        await tester.tap(find.byKey(Key('coin-${coin.id}')), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(s.onCounter.length, s.purse.length);
      final Rect counter = tester.getRect(find.byKey(const Key('counter'))).inflate(1);
      final Rect stage = tester.getRect(find.byKey(const Key('shop-stage'))).inflate(1);
      for (final String id in s.onCounter) {
        final Rect coin = tester.getRect(find.byKey(Key('on-$id')));
        expect(
          counter.contains(coin.topLeft) &&
              counter.contains(coin.bottomRight) &&
              stage.contains(coin.bottomRight),
          isTrue,
          reason: 'coin $id at $coin is outside the counter $counter',
        );
      }
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA-5 the eye ("show me") during the praise pause does not write "unsure" for an activity already answered right',
    (WidgetTester tester) async {
      final LessonController c = start('count-order', 0); // a spot-the-mistake activity
      final SpotErrorActivity a = c.current as SpotErrorActivity;
      final SpotErrorSession s = SpotErrorSession(c, a);
      await s.choose(a.wrong);
      expect(c.feedback, FeedbackKind.correct);
      // The frame keeps the eye and the lamp live until the lesson is finished (activity_frame.dart, lesson_screen.dart:441-443),
      // so a child who taps the eye while the praise is said reaches the controller.
      await tester.pump(const Duration(milliseconds: 500));
      await c.unsure();
      final List<AttemptRecord> mine = written.where((AttemptRecord r) => r.activityId == a.id).toList();
      expect(mine.map((AttemptRecord r) => r.result).toList(), <String>[
        'correct',
      ], reason: 'nothing after the right answer');
      s.dispose();
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'QA-6 number line, place mode: the frog the question talks about is on the stage before the child answers',
    (WidgetTester tester) async {
      final LessonController c = start('frog-line-10', 0); // b.numb13.1: "the frog wants to stand on three"
      final NumberLineActivity a = c.current as NumberLineActivity;
      expect(a.jump, isFalse);
      final NumberLineSession s = NumberLineSession(c, a);
      await host(tester, s);
      final Rect stage = tester.getRect(find.byKey(const Key('line-stage')));
      final Rect frog = tester.getRect(find.byKey(const Key('line-marker')));
      expect(
        stage.intersect(frog).width,
        greaterThan(frog.width * 0.9),
        reason: 'the frog is at $frog, the stage $stage',
      );
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA-13 trace, two strokes: a wrong second stroke does not wipe out a first stroke that was right',
    (WidgetTester tester) async {
      final LessonController c = start('trace-numbers-0-4', 4); // x.numb07.5: two strokes
      final TraceActivity a = c.current as TraceActivity;
      expect(a.strokes.length, 2);
      final TraceSession s = TraceSession(c, a);
      await stroke(s, a.strokes.first);
      expect(s.finished.length, 1);
      await stroke(s, const <Offset>[Offset(1, 1), Offset(3, 2)]);
      await pause(tester);
      expect(s.finished.length, 1, reason: 'the right first stroke should stay (design decision; see QA-13)');
      s.dispose();
      await tester.pump(const Duration(seconds: 3));
    },
    skip: _open,
  );

  test('QA-14 the child space has no English screen-reader labels (Hebrew-only app)', () {
    final RegExp english = RegExp(r'''semanticLabel:\s*'[A-Za-z]''');
    final List<String> hits = <String>[];
    for (final FileSystemEntity f in Directory('lib/play').listSync()) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final List<String> lines = f.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (english.hasMatch(lines[i])) {
          hits.add('${f.path.replaceAll(r'\', '/')}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  }, skip: _open);
}
