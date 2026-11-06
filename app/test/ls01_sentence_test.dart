// The sentence of the cloze and the stem (LS01, docs/design/languages-l5-ls01.md sections 4.1 and 7.9): where it breaks, what it is held to,
// and the dashed place of an order. Fixture course and fake clips, not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/ls01_metrics.dart';
import 'package:nitznutz/play/ls01_order_session.dart';
import 'package:nitznutz/play/ls01_sentence.dart';
import 'package:nitznutz/play/ls01_tap_session.dart';

import 'support/harness.dart';
import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

LangPack _cloze(String course, String text, List<String> options) {
  final LangPack p = LangPack(course)..addPictures(<String>['place-dog-on-chair']);
  p.add(
    clozeJson(
      course: course,
      id: 'x',
      band: 'B',
      text: text,
      picture: 'place-dog-on-chair',
      options: <Map<String, Object?>>[
        textOption('o1', options[0]),
        textOption('o2', options[1], tag: p.tag('lis.sem')),
        textOption('o3', options[2], tag: p.tag('lis.guess')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

Rig<Ls01TapSession> _rig(LangPack p) => Rig<Ls01TapSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01TapSession(c, a as TapAnswerActivity, band: Band.b),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  group('where a sentence breaks', () {
    test(
      'the Hebrew course keeps the gap with the word after it; English does not; a gap at the end is alone',
      () {
        expect(sentenceUnits('הַכֶּלֶב _ עַל הַכִּסֵּא.', gapWithNext: true), <List<int>>[
          <int>[0],
          <int>[1, 2],
          <int>[3],
        ]);
        expect(sentenceUnits('The dog is _ the chair.', gapWithNext: false), <List<int>>[
          <int>[0],
          <int>[1],
          <int>[2],
          <int>[3],
          <int>[4],
          <int>[5],
        ]);
        expect(sentenceUnits('הַכֶּלֶב הוֹלֵךְ _', gapWithNext: true), <List<int>>[
          <int>[0],
          <int>[1],
          <int>[2],
        ]);
      },
    );

    testWidgets(
      'in Hebrew the gap and the word after it stand on one line, the gap in the middle of the line when there is room',
      (WidgetTester t) async {
        // On the phone SE the column is 166 wide: the gap and "על" make one unit, and it goes to the second line together.
        final Rig<Ls01TapSession> se = _rig(
          _cloze('heb', 'הַכֶּלֶב _ עַל הַכִּסֵּא.', <String>['שָׁם', 'פֹּה', 'כָּאן']),
        );
        await se.pump(t, size: const Size(667, 375));
        final Rect gap = t.getRect(find.byKey(const Key('sentence-word-1')));
        final Rect on = t.getRect(find.byKey(const Key('sentence-word-2')));
        expect(
          (gap.bottom - on.bottom).abs(),
          lessThan(2),
          reason: 'the gap and the word after it are on one line',
        );
        await se.done(t);
        // On a tablet the whole sentence is one line, and the gap stands between two words.
        final Rig<Ls01TapSession> wide = _rig(
          _cloze('heb', 'הַכֶּלֶב _ עַל הַכִּסֵּא.', <String>['שָׁם', 'פֹּה', 'כָּאן']),
        );
        await wide.pump(t, size: const Size(1180, 820));
        final Rect first = t.getRect(find.byKey(const Key('sentence-word-0')));
        final Rect gap2 = t.getRect(find.byKey(const Key('sentence-word-1')));
        final Rect last = t.getRect(find.byKey(const Key('sentence-word-3')));
        expect((first.bottom - last.bottom).abs(), lessThan(2));
        expect(
          gap2.center.dx,
          lessThan(first.center.dx),
          reason: 'the gap comes after the first word, to its left in Hebrew',
        );
        expect(gap2.center.dx, greaterThan(last.center.dx));
        await wide.done(t);
      },
    );
  });

  group('a sentence is held to its zone', () {
    test(
      'the scale is the system\'s, lowered in steps while it does not fit, and never below the reading size',
      () {
        final Ls01Metrics m = Ls01Metrics(band: Band.b, tablet: false, course: 'eng');
        const String text = 'The dog is _ the chair.';
        final double gap = m.textWidth('at', FaceKind.line);
        // Room enough: the system's scale stands. Too little height: it comes down, to 1 at the lowest.
        expect(
          fitSentenceScale(
            m,
            text,
            FaceKind.line,
            const TextScaler.linear(1.3),
            gapTextWidth: gap,
            column: 600,
            height: 300,
          ),
          closeTo(1.3, 0.001),
        );
        final double tight = fitSentenceScale(
          m,
          text,
          FaceKind.line,
          const TextScaler.linear(1.3),
          gapTextWidth: gap,
          column: 166,
          height: 144,
        );
        expect(tight, lessThan(1.3));
        expect(tight, greaterThanOrEqualTo(1));
        expect(
          measureSentence(m, text, FaceKind.line, gapTextWidth: gap, column: 166, scale: tight).height,
          lessThanOrEqualTo(144.01),
        );
        // A smaller system scale is not obeyed: a text is never drawn below its reading size.
        expect(
          fitSentenceScale(
            m,
            text,
            FaceKind.line,
            const TextScaler.linear(0.8),
            gapTextWidth: gap,
            column: 166,
            height: 144,
          ),
          1,
        );
      },
    );

    test('three lines of English fit the SE stage with the reading bars, which take no room', () {
      final Ls01Metrics m = Ls01Metrics(band: Band.b, tablet: false, course: 'eng');
      final double gap = m.textWidth('on', FaceKind.line);
      final SentenceMeasure at = measureSentence(
        m,
        'The dog is _ the chair.',
        FaceKind.line,
        gapTextWidth: gap,
        column: 166,
      );
      expect(at.lines, 3);
      expect(at.height, lessThanOrEqualTo(144));
    });
  });

  group('the order place', () {
    testWidgets('an empty place is dashed and a place with a tile in it is solid', (WidgetTester t) async {
      final LangPack p = LangPack('eng')..addPictures(<String>['cat']);
      p.add(
        orderJson(
          course: 'eng',
          id: 'x',
          band: 'B',
          model: <String>['txt:s', 'txt:a'],
          palette: <String>['txt:t', 'txt:p', 'txt:n'],
          sequence: <String>['txt:t', 'txt:p'],
          tag: p.tag('lis.sem'),
        ),
      );
      final Rig<Ls01OrderSession> r = Rig<Ls01OrderSession>(
        p,
        'x',
        (LessonController c, Activity a) => Ls01OrderSession(c, a as BuildPatternActivity, band: Band.b),
      );
      await r.pump(t);
      expect(find.byKey(const Key('order-slot-dashed-0')), findsOneWidget);
      expect(find.byKey(const Key('order-slot-dashed-1')), findsOneWidget);
      await t.tap(r.tile('p0'));
      await r.wait(t, 300);
      expect(
        find.byKey(const Key('order-slot-dashed-0')),
        findsNothing,
        reason: 'the place holds a tile: solid',
      );
      expect(find.byKey(const Key('order-slot-dashed-1')), findsOneWidget);
      await r.done(t);
    });
  });
}
