// Batch C1 (2026-11-07): the layout of a stage that holds pictures and a row (QA-C1-1), the numerals on one line (QA-C1-2), the speech
// bubble that never lies over a tile (QA-C1-3), no dots above ten (QA-C1-7), and the three modes that came with the batch: the stage
// picture of blocks, the hundred chart and the number answer on a keypad (QA-C1-5).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/count_tap_session.dart' show Dots;
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/number_entry.dart';
import 'package:nitznutz/play/number_rules.dart';
import 'package:nitznutz/play/stage_pictures.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/c1_screens.dart';
import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  TapAnswerActivity tap(String id) => content.activities[id]! as TapAnswerActivity;

  LessonController controllerFor(Activity a, List<AttemptRecord> into) => LessonController(
    content: content,
    lesson: Lesson.mission(
      id: 'one',
      itemIds: <String>[a.id],
      skillIds: <String>[a.skillId],
      celebration: content.lessons['butterflies']!.celebration,
    ),
    profileId: 'p-1',
    clock: FixedClock(1793000000000),
    record: (AttemptRecord r) async => into.add(r),
  );

  group('QA-C1-1: a number sentence over two pictures keeps the row clear of them', () {
    for (final (String name, Size size) in boards) {
      testWidgets('on the $name board the row stands under the two ten-frames and inside the stage', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        for (final String id in <String>['c.mathc01.1', 'c.mathc01.5', 'c.mathc01.9', 'c.mathc01.13']) {
          await openOne(t, content, tap(id));
          final Rect stage = t.getRect(find.byKey(const Key('lesson-stage')));
          final Rect groups = t.getRect(find.byKey(const Key('tap-groups')));
          final Rect row = t.getRect(find.byKey(const Key('tap-row')));
          expect(
            groups.bottom,
            lessThanOrEqualTo(row.top + 0.5),
            reason: '$id: the row is over the pictures',
          );
          expect(
            stage.inflate(0.5).contains(row.topLeft) && stage.inflate(0.5).contains(row.bottomRight),
            isTrue,
            reason: '$id: row $row, stage $stage',
          );
          expect(row.height, greaterThanOrEqualTo(24), reason: '$id: the row is still readable');
          await closeOne(t);
        }
      });
    }
  });

  group('QA-C1-2 and QA-C1-7: a numeral stays on one line, and the dots go where they can be counted', () {
    for (final (String name, Size size) in boards) {
      testWidgets('on the $name board three-digit tiles are one line each and throw nothing', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        await collectErrors((List<dynamic> sink) async {
          for (final String id in <String>['c.numc02.1', 'c.numc03.1', 'c.numc01.5', 'c.mathc03.1']) {
            await openOne(t, content, tap(id));
            for (final Element e in find.byKey(const Key('answer-tile')).evaluate()) {
              final Rect tile = t.getRect(find.byWidget(e.widget));
              final Finder digits = find.descendant(of: find.byWidget(e.widget), matching: find.byType(Text));
              final Rect text = t.getRect(digits.first);
              // One line: the text is no taller than a single line of the tile's numeral, and inside the tile.
              expect(text.height, lessThan(tile.height * 0.7), reason: id);
              expect(
                tile.contains(text.topLeft) && tile.contains(text.bottomRight),
                isTrue,
                reason: '$id: $text in $tile',
              );
            }
            await closeOne(t);
          }
          expect(sink, isEmpty, reason: sink.map((d) => d.exceptionAsString()).join('\n'));
        });
      });
    }

    test('dots stand under 1 to 10 only, and never under the answers of the facts', () {
      final TapAnswerActivity facts = tap('c.mathc01.4');
      final TapAnswerActivity other = tap('c.numc03.1');
      final TapAnswerActivity bridge = tap('c.numb06.1');
      expect(numeralHasDots(bridge, 7), isTrue);
      expect(numeralHasDots(bridge, 10), isTrue);
      expect(numeralHasDots(bridge, 11), isFalse);
      expect(numeralHasDots(bridge, 0), isFalse);
      expect(numeralHasDots(other, 34), isFalse);
      expect(
        numeralHasDots(facts, 7),
        isFalse,
        reason: 'the facts: a row of dots would be a way to count the answer',
      );
    });

    testWidgets('no tile of the facts and none above ten draws dots', (WidgetTester t) async {
      await startOn(t, content, boards.first.$2);
      await openOne(t, content, tap('c.mathc01.4'));
      expect(find.byType(Dots), findsNothing);
      await closeOne(t);
      await openOne(t, content, tap('c.numb06.1'));
      expect(find.byType(Dots), findsNWidgets(tap('c.numb06.1').options.length));
      await closeOne(t);
    });
  });

  group('QA-C1-3: the speech bubble ends above the tiles at every size of text', () {
    for (final (String name, ActivitySpec spec) in <(String, ActivitySpec)>[
      ('phone', ActivitySpec.phone),
      ('phoneSE', ActivitySpec.phoneSE),
    ]) {
      testWidgets(
        'on the $name board a bubble of ${ActivityFrame.tileClear} or more clear of the tiles, long text shrinks',
        (WidgetTester t) async {
          final String longText = List<String>.filled(7, 'שָׁלוֹשׁ עֲשָׂרוֹת וְאַרְבַּע יְחִידוֹת').join(' ');
          for (final String text in <String>[
            'כַּמָּה זֶה?',
            longText.substring(0, 60),
            longText.substring(0, 140),
          ]) {
            await pumpScreen(
              t,
              ActivityFrame(
                spec: spec,
                bubbleText: text,
                stage: (Size room) => const SizedBox(),
                tiles: Container(key: const Key('tiles'), height: 96, color: Colors.white),
                trailTotal: 3,
                trailDone: 0,
                onHome: () {},
              ),
              size: spec.stage.width > 300 && spec.boardHeight == 375
                  ? const Size(667, 375)
                  : const Size(852, 393),
            );
            final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
            expect(
              bubble.bottom,
              lessThanOrEqualTo(spec.tilesTop - ActivityFrame.tileClear + 0.5),
              reason: text,
            );
          }
        },
      );
    }
  });

  group('QA-C1-5: the number answer', () {
    test('every wrong number is named by the item: an expected value, else a rule, else nothing', () {
      final TapAnswerActivity facts = tap(
        'c.mathc01.29',
      ); // 15 - 7 = ?  expected 22 (swap), 9 (double), 12 (smaller from larger)
      expect(facts.numberAnswer!.value, 8);
      expect(numberTag(facts, 8), '', reason: 'right');
      expect(numberTag(facts, 22), 'M-OP-SWAP');
      expect(numberTag(facts, 12), 'M-SUB-SMALLBIG');
      expect(numberTag(facts, 17), '', reason: 'nothing names it');
      final TapAnswerActivity place = tap('c.numc03.21'); // ? = 30 + 4: face_value
      expect(numberTag(place, 304), 'M-PV-ZERO');
      expect(numberTag(place, 7), 'M-PV-FACE', reason: '3 + 4 as digits');
      expect(
        numberTag(tap('c.numc03.22'), 5),
        'M-PV-FACE',
        reason: '58 = ? + 8: 5 is the tens digit at its face',
      );
      expect(numberTag(tap('c.mathc03.14'), 50), '');
    });

    test('the rules read the sentence: the other operation, the ten forgotten, a ten too many', () {
      final TapAnswerActivity sub = tap('c.mathc02.13'); // 15 - ? = 9 : 6
      expect(numberTag(sub, 24), 'M-OP-SWAP', reason: 'expected');
      final TapAnswerActivity add = tap('c.mathc01.27'); // 8 + 7 = ?
      expect(numberTag(add, 14), 'M-CNT-DOUBLE');
      expect(numberTag(add, 1), 'M-OP-SWAP', reason: 'the difference, 8 - 7');
    });

    test('a number the author does not know is no problem, whatever it is', () {
      final TapAnswerActivity a = tap('c.numc03.21');
      for (final int n in <int>[0, 1, 99999, -1, 1 << 40]) {
        expect(() => numberTag(a, n), returnsNormally, reason: '$n');
      }
    });

    test(
      'the controller marks a typed number right, and writes `n=34`; a wrong one carries its tag',
      () async {
        final TapAnswerActivity a = tap('c.numc03.21');
        final List<AttemptRecord> sent = <AttemptRecord>[];
        final LessonController c = controllerFor(a, sent);
        final Outcome wrong = await c.enterNumber(304);
        expect(wrong.correct, isFalse);
        expect(wrong.tag, 'M-PV-ZERO');
        final Outcome right = await c.enterNumber(34);
        expect(right.correct, isTrue);
        expect(
          sent.map((AttemptRecord r) => (r.result, r.response, r.misconceptionTag)),
          <(String, String, String)>[('incorrect', 'n=304', 'M-PV-ZERO'), ('correct', 'n=34', '')],
        );
        for (final AttemptRecord r in sent) {
          expect(ResponseCodeFits.fits(r.response), isTrue);
        }
      },
    );

    testWidgets(
      'the keypad types left to right, takes a digit off, never starts with 0, and checks the number',
      (WidgetTester t) async {
        await startOn(t, content, boards.first.$2);
        await openOne(t, content, tap('c.numc03.21'));
        Text shown() => t.widget<Text>(
          find.descendant(of: find.byKey(const Key('entry-cell')), matching: find.byType(Text)),
        );
        expect(shown().data, '?');
        for (final String k in <String>['0', '0', '3', '4', '9']) {
          await t.tap(find.byKey(Key('key-$k')));
          await t.pump();
        }
        expect(shown().data, '349');
        await t.tap(find.byKey(const Key('key-back')));
        await t.pump();
        expect(shown().data, '34');
        await t.tap(find.byKey(const Key('key-done')));
        await t.pump(const Duration(milliseconds: 300));
        // The right number: the cell has its golden ring and the lesson goes on after the praise.
        expect(find.byKey(const Key('lesson-celebration')), findsNothing);
        await waitSteps(t, 2500);
        await closeOne(t);
      },
    );

    testWidgets('a wrong number is "not yet": the cell is emptied for another try, nothing is called wrong', (
      WidgetTester t,
    ) async {
      await startOn(t, content, boards.first.$2);
      await openOne(t, content, tap('c.numc03.21'));
      for (final String k in <String>['7', 'done']) {
        await t.tap(find.byKey(Key('key-$k')));
        await t.pump();
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('7'), findsWidgets);
      await waitSteps(t, 1500);
      final Text cell = t.widget<Text>(
        find.descendant(of: find.byKey(const Key('entry-cell')), matching: find.byType(Text)),
      );
      expect(cell.data, '?');
      await closeOne(t);
    });
  });

  group('QA-C1-5: the stage pictures', () {
    test('blocks: the tens stand left of the ones, a rod is ten units tall, nothing overlaps', () {
      final BaseTenLayout l = BaseTenLayout.forBox(const BaseTen(tens: 3, ones: 4), const Size(300, 110));
      expect(l.tens, hasLength(3));
      expect(l.ones, hasLength(4));
      expect(l.tens.last.right, lessThan(l.ones.first.left), reason: 'tens left of ones, left to right');
      for (final Rect r in l.tens) {
        expect(r.height, closeTo(10 * l.unit, 0.01));
        expect(r.width, closeTo(l.unit, 0.01));
      }
      final List<Rect> all = l.all;
      for (int i = 0; i < all.length; i++) {
        for (int j = i + 1; j < all.length; j++) {
          expect(all[i].overlaps(all[j]), isFalse, reason: '$i and $j');
        }
        expect(const Rect.fromLTWH(0, 0, 300, 110).contains(all[i].topLeft), isTrue);
        expect(const Rect.fromLTWH(0, 0, 300, 110).inflate(0.01).contains(all[i].bottomRight), isTrue);
      }
    });

    test('blocks: a zero holds its place (50 is five rods and no cube), 9,999 still fits a small box', () {
      final BaseTenLayout fifty = BaseTenLayout.forBox(BaseTen.of(50), const Size(300, 110));
      expect(fifty.tens, hasLength(5));
      expect(fifty.ones, isEmpty);
      final BaseTenLayout big = BaseTenLayout.forBox(BaseTen.of(9999), const Size(270, 80));
      for (final Rect r in big.all) {
        expect(const Rect.fromLTWH(0, 0, 270, 80).inflate(0.01).contains(r.bottomRight), isTrue);
        expect(const Rect.fromLTWH(0, 0, 270, 80).inflate(0.01).contains(r.topLeft), isTrue);
      }
      expect(BaseTen.of(9999).value, 9999);
    });

    test('the chart shows the rows the question stands in and one more each way, never more than six, else all ten', () {
      ChartSpec of(List<int> lit, List<int> blank) => ChartSpec.around(lit.toSet(), blank.toSet());
      expect((of(<int>[34], <int>[44]).firstRow, of(<int>[34], <int>[44]).lastRow), (2, 5));
      expect((of(<int>[6, 16, 26], <int>[36]).firstRow, of(<int>[6, 16, 26], <int>[36]).lastRow), (0, 4));
      expect(of(<int>[3], <int>[93]).rows, 10, reason: 'too far apart for a window');
      final ChartLayout l = ChartLayout.forBox(of(<int>[34], <int>[44]), const Size(300, 110));
      final Rect a = l.cellOf(34)!;
      final Rect b = l.cellOf(44)!;
      expect(b.left, a.left, reason: 'ten more is the same column');
      expect(b.top, closeTo(a.bottom, 0.01), reason: 'one row down');
      expect(l.cellOf(35)!.left, closeTo(a.right, 0.01), reason: 'numbers run left to right');
      expect(l.cellOf(5), isNull, reason: 'a row outside the window');
      for (int n = 21; n <= 50; n++) {
        expect(const Rect.fromLTWH(0, 0, 300, 110).inflate(0.01).contains(l.cellOf(n)!.bottomRight), isTrue);
      }
    });

    for (final (String name, Size size) in boards) {
      testWidgets('on the $name board blocks, chart and keypad are drawn and throw nothing', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        await collectErrors((List<dynamic> sink) async {
          for (final String id in <String>['c.numc03.18', 'c.numc09.13', 'c.numc03.21', 'c.numc02.13']) {
            await openOne(t, content, tap(id));
            final TapAnswerActivity a = tap(id);
            if (a.drawnPictureKind == 'base_ten') {
              expect(find.byKey(const Key('stage-blocks')), findsOneWidget);
            }
            if (a.drawnPictureKind == 'hundred_chart') {
              expect(find.byKey(const Key('stage-chart')), findsOneWidget);
            }
            if (a.numberAnswer != null) {
              expect(find.byKey(const Key('keypad')), findsOneWidget);
              for (final String k in keypadKeys) {
                final Rect key = t.getRect(find.byKey(Key('key-$k')));
                expect(
                  key.width,
                  greaterThanOrEqualTo(56),
                  reason: '$id $k: a key is at least a Band C control',
                );
                expect(
                  key.bottom,
                  lessThanOrEqualTo(size.height - 24 + 0.5),
                  reason: '$id $k: not in the bottom band',
                );
              }
            }
            await closeOne(t);
          }
          expect(sink, isEmpty, reason: sink.map((d) => d.exceptionAsString()).join('\n'));
        });
      });
    }

    test('only a picture of a kind some session draws is played, the rest stay hidden', () {
      expect(drawnStagePictureKinds, <String>{'base_ten', 'hundred_chart'});
      expect(tap('c.numc03.18').drawnPictureKind, 'base_ten');
      expect(tap('c.numc09.13').drawnPictureKind, 'hundred_chart');
      expect(tap('c.numc03.1').drawnPictureKind, isNull);
      expect(content.activities.containsKey('c.numc03.18'), isTrue);
      expect(content.activities.containsKey('c.numc02.13'), isTrue, reason: 'a number answer is played');
    });

    test('a number answer has the keys of a keypad and its tips are on the top edge of each key', () {
      final TapAnswerActivity a = tap('c.numc03.21');
      const ActivitySpec spec = ActivitySpec.phone;
      final TapGeometry g = TapGeometry(a, spec.stage.size, spec);
      final KeypadLayout k = KeypadLayout.of(spec);
      expect(keypadKeys, hasLength(12));
      expect(g.keyTip('1').dy, k.top - spec.stage.top);
      expect(g.keyTip('6').dy, k.top - spec.stage.top + k.pitch);
      expect(g.keyTip('1').dx, lessThan(g.keyTip('5').dx), reason: 'left to right');
      expect(g.keyTip('done').dx, greaterThan(g.keyTip('0').dx));
    });
  });
}

/// The code of an answer fits what the server takes (`sync-push`): kept here so that a new code is noticed.
abstract final class ResponseCodeFits {
  static bool fits(String code) => RegExp(r'^[A-Za-z0-9=._-]{0,40}$').hasMatch(code);
}
