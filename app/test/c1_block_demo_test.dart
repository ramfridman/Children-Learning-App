// The demonstration that a rod is ten cubes (docs/design/c1-blocks.md section 6): its timeline, the frames of it as a picture, when a lesson
// opens with it (all of it for a child's first three lessons with blocks, then the short form), the eye that shows it again, and that any
// touch of the item ends it. The pack and its voice are real; no sound file is made (the line is pending, and the lesson goes on).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/block_demo.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/c1_screens.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);

Future<void> _openLesson(WidgetTester t, String id) async {
  final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LessonScreen(profileId: 'p-1', lessonId: id),
    ),
  );
  // The visit reads the child's look before it draws (B-29), which takes a few frames more than it did.
  for (int i = 0; i < 4; i++) {
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 600));
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
  });

  group('the timeline', () {
    const BlockDemoScript full = BlockDemoScript(BlockDemoKind.full);
    const BlockDemoScript short = BlockDemoScript(BlockDemoKind.short);

    test('the whole demonstration is about nine seconds, the short one two', () {
      expect(full.length.inMilliseconds, inInclusiveRange(8000, 9500));
      expect(short.length.inMilliseconds, inInclusiveRange(1800, 2300));
    });

    test('the cubes are counted 1 to 10, each lit for half a second, before they move', () {
      final List<int> seen = <int>[];
      for (int t = 0; t < full.snap.inMilliseconds; t += 50) {
        final BlockDemoFrame f = full.at(_ms(t));
        if (f.numeral != null && (seen.isEmpty || seen.last != f.numeral)) seen.add(f.numeral!);
        if (f.lit != null) {
          expect(f.numeral, f.lit! + 1);
          for (int i = 0; i < 10; i++) {
            expect(
              f.cubes[i],
              BlockDemoScript.inFrame(i),
              reason: 'no cube moves while they are counted (t $t)',
            );
          }
        }
      }
      expect(seen, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test(
      'they glide into a column, close up and snap; the rod stands whole at the snap, with the ring after it',
      () {
        final BlockDemoFrame before = full.at(full.snap - _ms(300));
        expect(before.cubes[9], isNot(BlockDemoScript.inFrame(9)));
        expect(before.rodAlpha, 0);
        final BlockDemoFrame whole = full.at(full.snap + _ms(BlockDemoScript.closing));
        expect(whole.rodAlpha, 1);
        expect(whole.cubeAlpha, 0);
        for (int i = 0; i < 10; i++) {
          expect(whole.cubes[i].dx, -0.5);
          expect(whole.cubes[i].dy, closeTo(i.toDouble(), 1e-9), reason: 'the gaps are closed');
        }
        expect(full.at(full.snap + _ms(BlockDemoScript.closing + 100)).ringAlpha, greaterThan(0));
        expect(full.at(full.length).fade, 0, reason: 'the picture has gone when the item begins');
      },
    );

    test('the short form has no counting, no numeral and no tile', () {
      for (int t = 0; t < short.length.inMilliseconds; t += 50) {
        final BlockDemoFrame f = short.at(_ms(t));
        expect(f.numeral, isNull);
        expect(f.lit, isNull);
        expect(f.tileAlpha, 0);
      }
      expect(
        short.at(_ms(500)).cubes[9],
        isNot(BlockDemoScript.inFrame(9)),
        reason: 'it starts with the glide',
      );
    });

    test('with reduce motion the cubes light in place and the picture fades to the rod', () {
      const BlockDemoScript still = BlockDemoScript(BlockDemoKind.full, reduced: true);
      for (int t = 0; t < still.length.inMilliseconds; t += 50) {
        final BlockDemoFrame f = still.at(_ms(t));
        for (int i = 0; i < 10; i++) {
          expect(f.cubes[i], BlockDemoScript.inFrame(i), reason: 'nothing glides (t $t)');
        }
      }
      expect(still.at(still.snap - _ms(10)).rodAlpha, lessThan(0.1));
      expect(still.at(still.snap + _ms(300)).rodAlpha, 1);
      expect(still.length, lessThan(full.length));
    });
  });

  group('the picture of the frames', () {
    testWidgets('five moments on the phone stage: the ten, counted, gliding, snapped, the rod and its 10', (
      WidgetTester t,
    ) async {
      const BlockDemoScript script = BlockDemoScript(BlockDemoKind.full);
      final List<Duration> moments = <Duration>[
        _ms(500),
        _ms(3300),
        _ms(6000),
        script.snap + _ms(BlockDemoScript.closing + 150),
        script.snap + _ms(BlockDemoScript.closing + 900),
      ];
      await pumpScreen(
        t,
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: Wrap(
            textDirection: TextDirection.ltr,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final Duration m in moments)
                SizedBox(
                  width: 330,
                  height: 165,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: const Color(0xFFE3F4FC),
                      child: CustomPaint(
                        painter: BlockDemoPainter(script.at(m), BlockDemo.unitFor(const Size(330, 165), 22)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        size: const Size(1050, 360),
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/c1_block_demo_frames.png'));
    });
  });

  group('in a lesson', () {
    testWidgets(
      'a lesson with blocks opens with the whole demonstration for the first three, then the short one',
      (WidgetTester t) async {
        final AppRig rig = await startOn(t, content, const Size(852, 393));
        await _openLesson(t, 'blocks-tens-and-ones');
        expect(find.byKey(const Key('block-demo')), findsOneWidget, reason: 'the first item has rods');
        expect(find.byKey(const Key('stage-blocks')), findsNothing, reason: 'the picture of the item waits');
        // The rig turns "reduce motion" on: the demonstration keeps its own reduced length (about seven seconds), it is not cut to a twentieth.
        await waitSteps(t, 3000);
        expect(
          find.byKey(const Key('block-demo')),
          findsOneWidget,
          reason: 'QA-C1c-2: still on after three seconds',
        );
        await waitSteps(t, 5000);
        expect(find.byKey(const Key('block-demo')), findsNothing, reason: 'it ends by itself');
        expect(find.byKey(const Key('stage-blocks')), findsOneWidget, reason: 'and the item begins');
        expect(await rig.db.setting('blocks.demo.p-1'), '1');
        t.state<NavigatorState>(find.byType(Navigator).first).pop();
        await t.pump(const Duration(milliseconds: 400));

        // A child who has had three of them gets the short form: it is over in under a second with reduce motion.
        await rig.db.putSetting('blocks.demo.p-1', '3');
        await _openLesson(t, 'blocks-tens-and-ones');
        expect(find.byKey(const Key('block-demo')), findsOneWidget);
        await waitSteps(t, 1200);
        expect(find.byKey(const Key('block-demo')), findsNothing);
      },
    );

    testWidgets('a touch of an answer ends it, and the answer is taken', (WidgetTester t) async {
      await startOn(t, content, const Size(852, 393));
      await _openLesson(t, 'blocks-tens-and-ones');
      expect(find.byKey(const Key('block-demo')), findsOneWidget);
      final TapAnswerActivity a = content.activities['c.numc03.18']! as TapAnswerActivity;
      await t.tap(find.byKey(Key('tile-${a.options.first.id}')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('block-demo')), findsNothing);
      expect(find.byKey(const Key('stage-blocks')), findsOneWidget);
      await waitSteps(t, 3000);
    });

    testWidgets('a lesson that opens with no demonstration (a single item) has none, and the eye shows it', (
      WidgetTester t,
    ) async {
      await startOn(t, content, const Size(852, 393));
      await openOne(t, content, content.activities['c.numc03.18']!);
      expect(find.byKey(const Key('block-demo')), findsNothing);
      await t.tap(find.byKey(const Key('lesson-show-me')));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('block-demo')), findsOneWidget);
      await waitSteps(t, 8000);
      expect(find.byKey(const Key('block-demo')), findsNothing);
      await closeOne(t);
    });

    testWidgets(
      'QA-C1c-1: a touch anywhere ends it: the stage, the guide, the bubble, the replay button, an empty corner',
      (WidgetTester t) async {
        final AppRig rig = await startOn(t, content, const Size(852, 393));
        final Map<String, Offset Function()> places = <String, Offset Function()>{
          'the stage picture': () => t.getCenter(find.byKey(const Key('block-demo'))),
          'the guide': () => t.getCenter(find.byKey(const Key('activity-nitzi'))),
          'the bubble': () => t.getCenter(find.byKey(const Key('bubble-body'))),
          'the replay button': () => t.getCenter(find.byKey(const Key('lesson-replay'))),
          'an empty corner': () => const Offset(260, 50),
        };
        for (final MapEntry<String, Offset Function()> place in places.entries) {
          await rig.db.putSetting('blocks.demo.p-1', '0');
          await _openLesson(t, 'blocks-tens-and-ones');
          expect(find.byKey(const Key('block-demo')), findsOneWidget, reason: place.key);
          await waitSteps(t, 500);
          await t.tapAt(place.value());
          await t.pump(const Duration(milliseconds: 100));
          expect(
            find.byKey(const Key('block-demo')),
            findsNothing,
            reason: 'a touch on ${place.key} ends it',
          );
          expect(
            find.byKey(const Key('stage-blocks')),
            findsOneWidget,
            reason: 'and the item begins (${place.key})',
          );
          await waitSteps(t, 2000);
          t.state<NavigatorState>(find.byType(Navigator).first).pop();
          await t.pump(const Duration(milliseconds: 400));
        }
      },
    );

    testWidgets(
      'QA-C1c-4: the line of the demonstration is in the bubble at the snap, and the question is back when it ends',
      (WidgetTester t) async {
        await startOn(t, content, const Size(852, 393));
        await _openLesson(t, 'blocks-tens-and-ones');
        final TapAnswerActivity first = content.activities['c.numc03.18']! as TapAnswerActivity;
        String said() => t
            .widgetList<Text>(
              find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
            )
            .first
            .data!;
        final String caption = content.lessons['blocks-tens-and-ones']!.demo!.caption;
        expect(caption, 'עֶשֶׂר קֻבִּיּוֹת הֵן מוֹט אֶחָד.');
        expect(said(), isNot(caption), reason: 'before the snap the bubble has the question');
        // Reduced motion: the rod is whole at the snap, 6.4 s in. The visit now reads the child's look before it draws (B-29), so the
        // demonstration starts a little after the lesson was opened.
        for (int i = 0; i < 45 && said() != caption; i++) {
          await waitSteps(t, 200);
        }
        expect(said(), caption, reason: 'at the snap');
        await waitSteps(t, 1500);
        expect(find.byKey(const Key('block-demo')), findsNothing);
        expect(
          said(),
          first.promptLine.caption,
          reason: 'the question is back when the demonstration has ended',
        );
      },
    );

    testWidgets('an item with no rod has no demonstration, and the eye does not make one', (
      WidgetTester t,
    ) async {
      await startOn(t, content, const Size(852, 393));
      await openOne(t, content, content.activities['c.numc01.1']!);
      await t.tap(find.byKey(const Key('lesson-show-me')));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('block-demo')), findsNothing);
      await waitSteps(t, 500);
      await closeOne(t);
    });
  });
}
