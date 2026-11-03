// F1, direction-aware text runs (docs/languages/frame.md section 2.1): a course has a reading direction, a target word is an
// isolated run in it, a prompt never prints a target word inline (it goes in a chip on its own line), and the rows of tiles and
// the stage follow the course, not the screen. Numbers and arrows are never mirrored. Fixture course, not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/design/course_text.dart';
import 'package:nitznutz/design/target_text.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/language_content.dart';

String _cp(int r) => String.fromCharCode(r);

const Map<String, Size> _boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

/// A three-picture activity of [course] with its answers on tiles.
TapAnswerActivity _threePictures(String course) {
  final LangPack p = LangPack(course);
  p.add(
    tapJson(
      course: course,
      id: 'rows.one',
      scene: <String, Object?>{'optionsOnTiles': true},
      options: <Map<String, Object?>>[
        pictureOption('o1', 'flower_red', tag: p.tag('lis.sem')),
        pictureOption('o2', 'flower_yellow'),
        pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
      ],
      correct: 'o2',
    ),
  );
  return p.content.activities['$course.rows.one']! as TapAnswerActivity;
}

LessonController _controllerFor(TapAnswerActivity a, PackContent content) => LessonController(
  content: content,
  lesson: Lesson.mission(
    id: 'one',
    itemIds: <String>[a.id],
    skillIds: <String>[a.skillId],
    celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
  ),
  profileId: 'p-1',
  clock: FixedClock(1793000000000),
  record: (AttemptRecord r) async {},
);

void main() {
  setUpAll(loadAppFonts);

  group('the direction of a course', () {
    test('English and Russian read left to right, Hebrew and every land right to left', () {
      expect(directionOfCourse('eng'), TextDirection.ltr);
      expect(directionOfCourse('rus'), TextDirection.ltr);
      expect(directionOfCourse('heb'), TextDirection.rtl);
      expect(directionOfCourse('core'), TextDirection.rtl);
    });

    test(
      'a row follows the course only in a language course; a land follows the screen as it always did',
      () {
        expect(courseRowDirection('eng'), TextDirection.ltr);
        expect(courseRowDirection('rus'), TextDirection.ltr);
        expect(courseRowDirection('heb'), TextDirection.rtl);
        expect(courseRowDirection('core'), isNull);
      },
    );

    test('English and Russian are set in the teaching font; Hebrew keeps Heebo', () {
      expect(targetLanguageOf('eng'), TargetLanguage.english);
      expect(targetLanguageOf('rus'), TargetLanguage.russian);
      expect(targetLanguageOf('heb'), isNull);
      expect(targetLanguageOf('core'), isNull);
    });
  });

  group('CourseText', () {
    testWidgets(
      'English and Russian: the teaching font, the language tag, left to right in a right to left screen',
      (WidgetTester t) async {
        await pumpScreen(
          t,
          const Column(
            children: <Widget>[
              CourseText('sun', course: 'eng', size: 30),
              CourseText('солнце', course: 'rus', size: 30, bold: true),
            ],
          ),
        );
        final Text en = t.widget<Text>(find.text('sun'));
        final Text ru = t.widget<Text>(find.text('солнце'));
        expect(en.style!.fontFamily, 'NitznutzLetters');
        expect(en.locale, const Locale('en'));
        expect(en.textDirection, TextDirection.ltr);
        expect(ru.locale, const Locale('ru'));
        expect(ru.style!.fontWeight, FontWeight.w700);
        expect(ru.textDirection, TextDirection.ltr);
      },
    );

    testWidgets('Hebrew: Heebo, the nikud line height, right to left, never the teaching font', (
      WidgetTester t,
    ) async {
      await pumpScreen(t, const CourseText('שָׁלוֹם', course: 'heb', size: 30));
      final Text w = t.widget<Text>(find.text('שָׁלוֹם'));
      expect(w.style!.fontFamily, TokenFonts.text);
      expect(w.style!.height, 1.7);
      expect(w.textDirection, TextDirection.rtl);
      expect(w.locale, const Locale('he'));
    });
  });

  group('an isolated run', () {
    test('isolateLtr wraps a run in the left-to-right isolate and nothing else', () {
      final String s = isolateLtr('sun');
      expect(s.runes.toList(), <int>[0x2066, ...'sun'.runes, 0x2069]);
    });

    test('SEC-L1-6: a direction control inside the run is taken out, so the run cannot close its isolate or reach out', () {
      final String s = isolateLtr('a${_cp(0x2069)}${_cp(0x202E)}b${_cp(0x2066)}${_cp(0x200F)}');
      expect(s.runes.toList(), <int>[0x2066, 0x61, 0x62, 0x2069]);
    });

    testWidgets('inside a Hebrew line an isolated run keeps its own order and sits where the line puts it', (
      WidgetTester t,
    ) async {
      // alef (right), then the run "abc" (left to right inside it), then bet at the left end.
      final String text = 'א ${isolateLtr('abc')} ב';
      final TextPainter p = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontFamily: 'Heebo', fontSize: 30),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      double left(int from, int to) =>
          p.getBoxesForSelection(TextSelection(baseOffset: from, extentOffset: to)).first.left;
      final int a = text.indexOf('a');
      expect(left(0, 1), greaterThan(left(a, a + 3)), reason: 'alef is to the right of the run');
      expect(left(a, a + 3), greaterThan(left(text.length - 1, text.length)), reason: 'bet is to its left');
      expect(left(a, a + 1), lessThan(left(a + 1, a + 2)), reason: 'a before b');
      expect(left(a + 1, a + 2), lessThan(left(a + 2, a + 3)), reason: 'b before c');
    });

    testWidgets('numbers and arrows in a target run are not mirrored', (WidgetTester t) async {
      await pumpScreen(
        t,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: const <Widget>[
              CourseText('12', course: 'eng', size: 30),
              CourseText('->', course: 'eng', size: 30),
              CourseText('13', course: 'eng', size: 30),
            ],
          ),
        ),
      );
      // A row in a right to left screen starts at the right, but each run reads left to right.
      for (final String s in <String>['12', '->', '13']) {
        expect(t.widget<Text>(find.text(s)).textDirection, TextDirection.ltr);
      }
      final Text two = t.widget<Text>(find.text('12'));
      expect(two.data, '12', reason: 'digits stay in reading order');
    });
  });

  group('the chip', () {
    testWidgets('a target word is a chip: the word alone, in its own box, in its font, left to right', (
      WidgetTester t,
    ) async {
      await pumpScreen(t, const Center(child: TargetChip('sun', course: 'eng', size: 30)));
      final Finder chip = find.byKey(const Key('target-chip'));
      expect(chip, findsOneWidget);
      final Text word = t.widget<Text>(find.descendant(of: chip, matching: find.byType(Text)));
      expect(word.data, 'sun', reason: 'the word and nothing beside it: no punctuation, no Hebrew');
      expect(word.style!.fontFamily, 'NitznutzLetters');
      expect(t.getSize(chip).height, closeTo(TargetChip.heightFor(30), 8));
    });

    for (final MapEntry<String, Size> b in _boards.entries) {
      testWidgets(
        '${b.key}: the guide\'s line and the chip are two rows of one bubble, the chip under the line',
        (WidgetTester t) async {
          await pumpScreen(
            t,
            ActivityFrame(
              bubbleText: 'הַקְשִׁיבוּ לַמִּלָּה שֶׁעַל הַמָּסָךְ.',
              bubbleTarget: (text: 'sun', course: 'eng'),
              stage: (Size room) => SizedBox(width: room.width, height: room.height),
              trailTotal: 3,
              trailDone: 1,
              onHome: () {},
            ),
            size: b.value,
            band: Band.a,
          );
          final Rect body = t.getRect(find.byKey(const Key('bubble-body')));
          final Rect chip = t.getRect(find.byKey(const Key('target-chip')));
          final Rect hebrew = t.getRect(find.textContaining('הַקְשִׁיבוּ'));
          expect(
            chip.top,
            greaterThanOrEqualTo(hebrew.bottom),
            reason: 'the chip is on its own row, under the line',
          );
          expect(body.contains(chip.topLeft) && body.contains(chip.bottomRight), isTrue);
          final ActivitySpec spec = ActivitySpec.of(boardClassFor(b.value));
          expect(
            body.height,
            lessThanOrEqualTo(spec.bubbleMaxHeight + 1),
            reason: 'the line gave way to the chip',
          );
          expect(
            find.textContaining('sun'),
            findsOneWidget,
            reason: 'the word is shown once, only in the chip',
          );
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets('with no word there is no chip and the bubble is what it was', (WidgetTester t) async {
      await pumpScreen(
        t,
        ActivityFrame(
          bubbleText: 'הַקְשִׁיבוּ',
          stage: (Size room) => SizedBox(width: room.width, height: room.height),
          trailTotal: 3,
          trailDone: 1,
          onHome: () {},
        ),
      );
      expect(find.byKey(const Key('target-chip')), findsNothing);
    });
  });

  group('rows follow the course', () {
    const Size stage = Size(330, 128);
    const ActivitySpec spec = ActivitySpec.phone;

    test('the hint\'s tiles run left to right in English, right to left in Hebrew and in a land', () {
      final TapAnswerActivity en = _threePictures('eng');
      final TapAnswerActivity he = _threePictures('heb');
      TapGeometry g(TapAnswerActivity a) =>
          TapGeometry(a, stage, spec, dir: courseRowDirection(a.course) ?? TextDirection.rtl);
      expect(g(en).optionTip(0).dx, lessThan(g(en).optionTip(1).dx));
      expect(g(en).optionTip(1).dx, lessThan(g(en).optionTip(2).dx));
      expect(g(he).optionTip(0).dx, greaterThan(g(he).optionTip(1).dx));
      expect(g(he).optionTip(1).dx, greaterThan(g(he).optionTip(2).dx));
    });

    test(
      'the pictures on the stage start from the right in Hebrew, from the left in English and in a land',
      () {
        TapAnswerActivity onStage(String course) {
          final LangPack p = LangPack(course);
          p.add(
            tapJson(
              course: course,
              id: 'rows.stage',
              options: <Map<String, Object?>>[
                pictureOption('o1', 'flower_red', tag: p.tag('lis.sem')),
                pictureOption('o2', 'flower_yellow'),
                pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
              ],
              correct: 'o2',
            ),
          );
          return p.content.activities['$course.rows.stage']! as TapAnswerActivity;
        }

        for (final (String, bool) c in <(String, bool)>[('eng', false), ('rus', false), ('heb', true)]) {
          final TapAnswerActivity a = onStage(c.$1);
          final List<Rect> r = TapGeometry(a, stage, spec).stageOptions();
          expect(
            r[0].left < r[1].left,
            !c.$2,
            reason: '${c.$1}: the first picture is on the ${c.$2 ? 'right' : 'left'}',
          );
          expect(r[1].left < r[2].left, !c.$2);
        }
        // A land: the first picture on the left, as it has always been.
        final Map<String, Object?> land = <String, Object?>{
          ...tapJson(
            course: 'core',
            id: 'rows.land',
            skill: 'NUM-A-03',
            options: <Map<String, Object?>>[
              pictureOption('o1', 'flower_red'),
              pictureOption('o2', 'flower_yellow'),
            ],
            correct: 'o1',
          ),
        };
        final TapAnswerActivity a =
            Activity.fromJson(land, PackAssets(const <String, String>{})) as TapAnswerActivity;
        final List<Rect> r = TapGeometry(a, stage, spec).stageOptions();
        expect(r[0].left, lessThan(r[1].left));
      },
    );

    for (final (String course, bool first) in <(String, bool)>[
      ('eng', true),
      ('rus', true),
      ('heb', false),
    ]) {
      testWidgets(
        '$course: the answer tiles of the screen: the first tile is on the ${first ? 'left' : 'right'}',
        (WidgetTester t) async {
          final LangPack p = LangPack(course);
          p.add(
            tapJson(
              course: course,
              id: 'rows.tiles',
              scene: <String, Object?>{'optionsOnTiles': true},
              options: <Map<String, Object?>>[
                pictureOption('o1', 'flower_red', tag: p.tag('lis.sem')),
                pictureOption('o2', 'flower_yellow'),
                pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
              ],
              correct: 'o2',
            ),
          );
          final PackContent content = p.content;
          final TapAnswerActivity a = content.activities['$course.rows.tiles']! as TapAnswerActivity;
          final TapAnswerSession s = TapAnswerSession(_controllerFor(a, content), a);
          addTearDown(s.dispose);
          await pumpScreen(
            t,
            Builder(
              builder: (BuildContext c) => ActivityFrame(
                bubbleText: 'x',
                stage: (Size room) => s.buildStage(c, room, spec),
                tiles: s.buildTiles(c, spec),
                trailTotal: 3,
                trailDone: 1,
                onHome: () {},
              ),
            ),
            band: Band.a,
          );
          final double x1 = t.getCenter(find.byKey(const Key('tile-o1'))).dx;
          final double x2 = t.getCenter(find.byKey(const Key('tile-o2'))).dx;
          final double x3 = t.getCenter(find.byKey(const Key('tile-o3'))).dx;
          expect(x1 < x2 && x2 < x3, first, reason: '$course: tiles at $x1, $x2, $x3');
          expect(x1 > x2 && x2 > x3, !first);
        },
      );
    }
  });
}
