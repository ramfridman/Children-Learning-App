// LS01 on the tap template (docs/languages/frame.md section 2.3): text tiles in the course's font and direction, a speaker that
// plays a tile's own clip without answering, sound buttons, a picture that says its word as it is chosen, the word under the
// right picture after the answer, and the layouts on the four boards. Fixture course and fake clips, not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/scripts.dart' show isSingleLetter;
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/parent/language_settings.dart' show StressMarks;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/caption_policy.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/option_faces.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/language_content.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

String _cp(int r) => String.fromCharCode(r);

/// What the session asked to be played.
class Heard {
  /// Each call as a sentence: `now vo:a vo:b` for clips that cut in, `after vo:a` for clips that wait their turn.
  final List<String> calls = <String>[];

  void call(List<String> ids, {bool replace = false}) =>
      calls.add('${replace ? 'now' : 'after'} ${ids.join(' ')}');
}

/// A session of the activity [id] of [p], with the attempts it writes and the clips it asks for.
class Rig {
  Rig(LangPack p, String id, {bool captions = false, bool stress = true}) {
    final PackContent content = p.content;
    activity = content.activities['${p.course}.$id']! as TapAnswerActivity;
    controller = LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'one',
        itemIds: <String>[activity.id],
        skillIds: <String>[activity.skillId],
        celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async => attempts.add(r),
    );
    session = TapAnswerSession(controller, activity, captions: captions, stress: stress)
      ..playClips = heard.call;
  }

  late final TapAnswerActivity activity;
  late final LessonController controller;
  late final TapAnswerSession session;
  final Heard heard = Heard();
  final List<AttemptRecord> attempts = <AttemptRecord>[];

  Future<void> pump(
    WidgetTester t, {
    Size size = const Size(852, 393),
    Band band = Band.a,
    String bubble = 'x',
  }) async {
    t.view.devicePixelRatio = 1;
    addTearDown(() {
      if (!session.disposed) session.dispose();
    });
    await pumpScreen(
      t,
      Builder(
        builder: (BuildContext c) {
          final ActivitySpec spec = session.layoutFor(ActivitySpec.of(boardClassFor(size)));
          return ActivityFrame(
            spec: spec,
            bubbleAboveTiles: true,
            bubbleText: bubble,
            stage: (Size room) => session.buildStage(c, room, spec),
            tiles: session.buildTiles(c, spec),
            trailTotal: 3,
            trailDone: 1,
            onHome: () {},
          );
        },
      ),
      size: size,
      band: band,
    );
  }

  /// Takes the screen down and lets the session go, with the timers of its last move.
  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    session.dispose();
  }

  Finder tile(String id) => find.byKey(Key('tile-$id'));

  Text textIn(WidgetTester t, String id) =>
      t.widget<Text>(find.descendant(of: tile(id), matching: find.byType(Text)));
}

/// An item of text tiles in [course], one for each word, the first right, each with its own clip when [clips] is true.
LangPack words(String course, List<String> w, {bool clips = true, String id = 'words', String? face}) {
  final LangPack p = LangPack(course);
  p.add(
    tapJson(
      course: course,
      id: id,
      options: <Map<String, Object?>>[
        for (final (int i, String word) in w.indexed)
          textOption(
            'o${i + 1}',
            word,
            tag: i == 0 ? null : p.tag(i.isOdd ? 'lis.sem' : 'lis.guess'),
            clip: clips ? 'vo:$course.$id.${'abcd'[i]}' : null,
          ),
      ],
      correct: 'o1',
      answer: <String, Object?>{'face': ?face},
    ),
  );
  return p;
}

void main() {
  setUpAll(loadAppFonts);

  group('text tiles', () {
    testWidgets('English: the words in the teaching font and the language tag, left to right', (
      WidgetTester t,
    ) async {
      final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
      await r.pump(t);
      for (final (String id, String word) in <(String, String)>[
        ('o1', 'cat'),
        ('o2', 'dog'),
        ('o3', 'sun'),
      ]) {
        final Text text = r.textIn(t, id);
        expect(text.data, word);
        expect(text.style!.fontFamily, 'NitznutzLetters');
        expect(text.locale, const Locale('en'));
        expect(text.textDirection, TextDirection.ltr);
      }
      final double x1 = t.getCenter(r.tile('o1')).dx;
      final double x2 = t.getCenter(r.tile('o2')).dx;
      final double x3 = t.getCenter(r.tile('o3')).dx;
      expect(x1 < x2 && x2 < x3, isTrue, reason: 'the first tile is on the left');
      await r.done(t);
    });

    testWidgets('Russian: the Russian tag, and the stress mark only when it is to show', (
      WidgetTester t,
    ) async {
      final String mama = 'ма${_cp(0x301)}ма';
      final Rig on = Rig(words('rus', <String>[mama, 'дом', 'сон']), 'words');
      await on.pump(t);
      expect(on.textIn(t, 'o1').data, mama);
      expect(on.textIn(t, 'o1').locale, const Locale('ru'));
      await on.done(t);

      final Rig off = Rig(words('rus', <String>[mama, 'дом', 'сон']), 'words', stress: false);
      await off.pump(t);
      expect(off.textIn(t, 'o1').data, 'мама', reason: 'a reader of Russian sees no stress marks');
      await off.done(t);
    });

    testWidgets('Hebrew: Heebo with the nikud line height, the first tile on the right', (
      WidgetTester t,
    ) async {
      final Rig r = Rig(words('heb', <String>['כֶּלֶב', 'חָתוּל', 'סוּס']), 'words');
      await r.pump(t);
      final Text text = r.textIn(t, 'o1');
      expect(text.style!.fontFamily, TokenFonts.text);
      expect(text.style!.height, 1.7);
      expect(text.textDirection, TextDirection.rtl);
      final double x1 = t.getCenter(r.tile('o1')).dx;
      final double x2 = t.getCenter(r.tile('o2')).dx;
      final double x3 = t.getCenter(r.tile('o3')).dx;
      expect(x1 > x2 && x2 > x3, isTrue);
      await r.done(t);
    });

    testWidgets(
      'a tap on the right tile writes a correct answer, a wrong one writes its tag; the response is the option id',
      (WidgetTester t) async {
        final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
        await r.pump(t);
        await t.tap(r.tile('o2'));
        await t.pump(const Duration(milliseconds: 50));
        expect(r.attempts.single.result, 'incorrect');
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        expect(
          r.attempts.single.response,
          'o2',
          reason: 'ids and numbers only: no word in the response code',
        );
        expect(r.attempts.single.skillId, 'ENG-A-02');
        await t.pump(const Duration(milliseconds: 1100));
        await t.tap(r.tile('o1'));
        await t.pump(const Duration(milliseconds: 50));
        expect(r.attempts.last.result, 'correct');
        expect(r.attempts.last.response, 'o1');
        expect(
          r.heard.calls,
          isEmpty,
          reason: 'a text tile says nothing when it is chosen: it has a speaker for that',
        );
        await r.done(t);
      },
    );

    testWidgets('a long word is scaled to its tile, never wrapped and never cut', (WidgetTester t) async {
      for (final MapEntry<String, Size> b in boards.entries) {
        final Rig r = Rig(words('eng', <String>['elephant', 'butterfly', 'caterpillar']), 'words');
        await r.pump(t, size: b.value);
        for (final String id in <String>['o1', 'o2', 'o3']) {
          final Rect tile = t.getRect(r.tile(id));
          final Rect word = t.getRect(find.descendant(of: r.tile(id), matching: find.byType(Text)));
          expect(
            tile.inflate(0.5).contains(word.topLeft) && tile.inflate(0.5).contains(word.bottomRight),
            isTrue,
            reason: '${b.key} $id: $word inside $tile',
          );
        }
        expect(t.takeException(), isNull, reason: b.key);
        await r.done(t);
      }
    });

    testWidgets('a single letter is a square tile with the letter large and bold', (WidgetTester t) async {
      final Rig r = Rig(words('eng', <String>['a', 'b', 'c'], face: 'letter'), 'words');
      await r.pump(t);
      expect(
        t.getSize(find.descendant(of: r.tile('o1'), matching: find.byKey(const Key('answer-tile')))).width,
        96,
      );
      expect(r.textIn(t, 'o1').style!.fontWeight, FontWeight.w700);
      expect(r.textIn(t, 'o1').style!.fontSize, 56);
      await r.done(t);
    });

    testWidgets('QA-L1-1: the item says its face, the text does not: words stay words, letters are letters', (
      WidgetTester t,
    ) async {
      // (course, options, the item's `face`, the font size and weight every tile has)
      for (final (String, List<String>, String?, double, FontWeight) c
          in <(String, List<String>, String?, double, FontWeight)>[
            ('eng', <String>['on', 'cat', 'sun'], null, 30.8, FontWeight.w500),
            ('eng', <String>['on', 'up', 'in'], 'word', 30.8, FontWeight.w500),
            ('rus', <String>['да', 'нет', 'ёж'], 'word', 30.8, FontWeight.w500),
            ('heb', <String>['בֵּן', 'טַל', 'דָּן'], 'word', 30.8, FontWeight.w500),
            ('heb', <String>['בֵּן', 'נוֹעָה', 'יַעַל'], null, 30.8, FontWeight.w500),
            ('eng', <String>['b', 'd', 'p'], 'letter', 56, FontWeight.w700),
            ('eng', <String>['sh', 'ch', 'th'], 'letter', 56, FontWeight.w700),
            ('heb', <String>['ב', 'כ', 'פ'], 'letter', 56, FontWeight.w700),
          ]) {
        final Rig r = Rig(words(c.$1, c.$2, face: c.$3), 'words');
        await r.pump(t);
        for (final String id in <String>['o1', 'o2', 'o3']) {
          expect(r.textIn(t, id).style!.fontSize, closeTo(c.$4, 0.01), reason: '${c.$2} ${c.$3} $id');
          expect(r.textIn(t, id).style!.fontWeight, c.$5, reason: '${c.$2} ${c.$3} $id');
        }
        // A letter item is square tiles; a word item is as wide as the row allows.
        final double width = t
            .getSize(find.descendant(of: r.tile('o1'), matching: find.byKey(const Key('answer-tile'))))
            .width;
        expect(width, c.$3 == 'letter' ? 96 : greaterThan(96), reason: '${c.$2} ${c.$3}');
        await r.done(t);
      }
    });

    test('isSingleLetter: a letter, a digraph or a letter with its marks; not a word', () {
      expect(isSingleLetter('a'), isTrue);
      expect(isSingleLetter('sh'), isTrue);
      expect(isSingleLetter('ma${_cp(0x301)}'), isTrue);
      expect(isSingleLetter('${_cp(0x5D1)}${_cp(0x5BC)}${_cp(0x5B8)}'), isTrue);
      expect(isSingleLetter('cat'), isFalse);
    });
  });

  group('a speaker on a tile', () {
    testWidgets('plays the tile\'s own clip and does not answer', (WidgetTester t) async {
      final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
      await r.pump(t);
      expect(find.byType(SpeakerMark), findsNWidgets(3));
      await t.tap(find.byKey(const Key('speaker-o2')));
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, <String>['now vo:eng.words.b'], reason: 'it plays at once, cutting what plays');
      expect(r.attempts, isEmpty, reason: 'a listen is not an answer');
      expect(r.session.chosenId, isNull);
      await r.done(t);
    });

    testWidgets('a tile with no clip has no speaker, still works, and shows its text', (
      WidgetTester t,
    ) async {
      final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun'], clips: false), 'words');
      await r.pump(t);
      expect(find.byType(SpeakerMark), findsNothing);
      expect(r.textIn(t, 'o1').data, 'cat');
      await t.tap(r.tile('o1'));
      await t.pump(const Duration(milliseconds: 50));
      expect(r.attempts.single.result, 'correct');
      await r.done(t);
    });

    testWidgets(
      'the speaker is under its tile, outside the tap margin of the tile, at the floor of the band; a tap on the tile answers',
      (WidgetTester t) async {
        for (final MapEntry<String, Size> b in boards.entries) {
          for (final (Band band, double floor) in <(Band, double)>[
            (Band.a, 64),
            (Band.b, 56),
            (Band.c, 56),
          ]) {
            final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
            await r.pump(t, size: b.value, band: band);
            final Rect tile = t.getRect(
              find.descendant(of: r.tile('o1'), matching: find.byKey(const Key('answer-tile'))),
            );
            final Rect speaker = t.getRect(find.byKey(const Key('speaker-o1')));
            final Rect tapArea = t.getRect(r.tile('o1'));
            expect(speaker.width, floor, reason: '${b.key} $band');
            expect(speaker.height, floor, reason: '${b.key} $band');
            expect(
              speaker.top,
              greaterThanOrEqualTo(tapArea.bottom - 0.01),
              reason: '${b.key}: under the tap area of the tile',
            );
            expect(speaker.center.dx, closeTo(tile.center.dx, 0.5), reason: 'centred under its tile');
            final double bottomLimit = b.value.height - 24;
            expect(
              speaker.bottom,
              lessThanOrEqualTo(bottomLimit + 0.01),
              reason: '${b.key} $band: above the no-hotspot edge',
            );
            // The whole tile still answers, even at its bottom edge, and the speaker does not.
            await t.tapAt(Offset(tile.center.dx, tile.bottom - 2));
            await t.pump(const Duration(milliseconds: 50));
            expect(r.attempts, hasLength(1), reason: '${b.key} $band: a tap on the tile answers');
            await r.done(t);
          }
        }
      },
    );
  });

  group('the bubble and the tiles with speakers', () {
    testWidgets(
      'a two-line Hebrew prompt stays clear of the tiles, on every board, and the speakers stay on the board',
      (WidgetTester t) async {
        const String line = 'הַקְשִׁיבוּ לַמִּלָּה, וּגְעוּ בַּמִּלָּה הַנְּכוֹנָה.';
        for (final MapEntry<String, Size> b in boards.entries) {
          final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
          await r.pump(t, size: b.value, bubble: line);
          final Rect tile = t.getRect(
            find.descendant(of: r.tile('o1'), matching: find.byKey(const Key('answer-tile'))),
          );
          expect(
            t.getRect(find.byKey(const Key('bubble-body'))).bottom,
            lessThanOrEqualTo(tile.top),
            reason: b.key,
          );
          expect(
            t.getRect(find.byKey(const Key('speaker-o3'))).bottom,
            lessThanOrEqualTo(b.value.height - 24),
            reason: b.key,
          );
          expect(t.takeException(), isNull, reason: b.key);
          await r.done(t);
        }
      },
    );

    testWidgets(
      'a board with the room keeps its tiles where they were; an item with no speaker is never moved',
      (WidgetTester t) async {
        final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
        expect(
          r.session.layoutFor(ActivitySpec.tabletLandscape).tilesTop,
          ActivitySpec.tabletLandscape.tilesTop,
        );
        expect(r.session.layoutFor(ActivitySpec.phone).tilesTop, lessThan(ActivitySpec.phone.tilesTop));
        final Rig quiet = Rig(words('eng', <String>['cat', 'dog', 'sun'], clips: false), 'words');
        expect(quiet.session.layoutFor(ActivitySpec.phone), same(ActivitySpec.phone));
        await r.done(t);
        await quiet.done(t);
      },
    );
  });

  group('sound buttons and pictures that say their word', () {
    LangPack buttons() {
      final LangPack p = LangPack();
      p.add(
        tapJson(
          id: 'snd',
          options: <Map<String, Object?>>[
            soundOption('o1', 'vo:eng.snd.a'),
            soundOption('o2', 'vo:eng.snd.b', tag: p.tag('lis.numword')),
            soundOption('o3', 'vo:eng.snd.c', tag: p.tag('lis.numword')),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    testWidgets('a button has a speaker and nothing else; a tap plays its clip and answers', (
      WidgetTester t,
    ) async {
      final Rig r = Rig(buttons(), 'snd');
      await r.pump(t);
      expect(find.byType(SoundFace), findsNWidgets(3));
      expect(find.descendant(of: r.tile('o1'), matching: find.byType(Text)), findsNothing);
      await t.tap(r.tile('o2'));
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, <String>['now vo:eng.snd.b']);
      expect(r.attempts.single.result, 'incorrect');
      expect(r.attempts.single.misconceptionTag, 'eng.lis.numword');
      expect(r.attempts.single.response, 'o2');
      await r.done(t);
    });

    testWidgets('a hint plays all the buttons again, in order, after the hint\'s own line', (
      WidgetTester t,
    ) async {
      final Rig r = Rig(buttons(), 'snd');
      await r.pump(t);
      r.controller.showHint();
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, <String>['after vo:eng.snd.a vo:eng.snd.b vo:eng.snd.c']);
      await t.pump(const Duration(milliseconds: 3000));
      await r.done(t);
    });

    testWidgets('a hint on text tiles plays nothing: only sound buttons play again', (WidgetTester t) async {
      final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
      await r.pump(t);
      r.controller.showHint();
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, isEmpty);
      await t.pump(const Duration(milliseconds: 3000));
      await r.done(t);
    });

    testWidgets('a picture on the stage says its word as it is chosen, and answers', (WidgetTester t) async {
      final LangPack p = LangPack();
      p.add(
        tapJson(
          id: 'pic',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'flower_red', clip: 'vo:eng.pic.a'),
            pictureOption('o2', 'flower_yellow', clip: 'vo:eng.pic.b', tag: p.tag('lis.sem')),
            pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      final Rig r = Rig(p, 'pic');
      await r.pump(t);
      await t.tap(find.byKey(const Key('option-o2')));
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, <String>['now vo:eng.pic.b']);
      expect(r.attempts.single.result, 'incorrect');
      await t.pump(const Duration(milliseconds: 1100));
      await t.tap(find.byKey(const Key('option-o3')));
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, hasLength(1), reason: 'a picture with no clip says nothing');
      await r.done(t);
    });

    testWidgets('a button whose voice was chosen by mic does not play its own clip over the child', (
      WidgetTester t,
    ) async {
      final Rig r = Rig(buttons(), 'snd');
      await r.pump(t);
      await r.session.chooseByVoice('o2');
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard.calls, isEmpty);
      expect(r.attempts.single.result, 'incorrect');
      await r.done(t);
    });
  });

  group('the word under the right picture after the answer', () {
    LangPack revealed() {
      final LangPack p = LangPack('rus');
      p.add(
        tapJson(
          course: 'rus',
          id: 'rev',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'flower_red', reveal: 'ро${_cp(0x301)}за'),
            pictureOption('o2', 'flower_yellow', tag: p.tag('lis.sem')),
            pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    double opacityOfCaption(WidgetTester t) => t
        .widget<AnimatedOpacity>(
          find
              .ancestor(of: find.byKey(const Key('reveal-caption')), matching: find.byType(AnimatedOpacity))
              .first,
        )
        .opacity;

    testWidgets(
      'it is there only after the right answer, in the course\'s font, and nothing moves when it appears',
      (WidgetTester t) async {
        final Rig r = Rig(revealed(), 'rev', captions: true);
        await r.pump(t);
        expect(find.byKey(const Key('reveal-caption')), findsOneWidget);
        expect(
          opacityOfCaption(t),
          0,
          reason: 'the item is still a listening item: the word is not shown yet',
        );
        final Rect before = t.getRect(find.byKey(const Key('option-o1')));
        await t.tap(find.byKey(const Key('option-o2')));
        await t.pump(const Duration(milliseconds: 50));
        expect(opacityOfCaption(t), 0, reason: 'a wrong answer shows nothing');
        await t.pump(const Duration(milliseconds: 1100));
        await t.tap(find.byKey(const Key('option-o1')));
        await t.pump(const Duration(milliseconds: 400));
        expect(opacityOfCaption(t), 1);
        expect(t.getRect(find.byKey(const Key('option-o1'))), before);
        final Text word = t.widget<Text>(
          find.descendant(of: find.byKey(const Key('reveal-caption')), matching: find.byType(Text)),
        );
        expect(word.data, 'ро${_cp(0x301)}за');
        expect(word.style!.fontFamily, 'NitznutzLetters');
        expect(word.locale, const Locale('ru'));
        expect(r.attempts.last.response, 'o1', reason: 'no word in the response code');
        await r.done(t);
      },
    );

    testWidgets('with captions off there is no caption and no room kept for one', (WidgetTester t) async {
      final Rig off = Rig(revealed(), 'rev');
      await off.pump(t);
      expect(find.byKey(const Key('reveal-caption')), findsNothing);
      final double pictureOff = t.getSize(find.byKey(const Key('option-o1'))).height;
      await off.done(t);
      final Rig on = Rig(revealed(), 'rev', captions: true);
      await on.pump(t);
      expect(t.getSize(find.byKey(const Key('option-o1'))).height, lessThan(pictureOff));
      await on.done(t);
    });

    testWidgets('the stress mark follows the route\'s display default', (WidgetTester t) async {
      final Rig r = Rig(revealed(), 'rev', captions: true, stress: false);
      await r.pump(t);
      final Text word = t.widget<Text>(
        find.descendant(of: find.byKey(const Key('reveal-caption')), matching: find.byType(Text)),
      );
      expect(word.data, 'роза');
      await r.done(t);
    });

    testWidgets('on tiles the word stands under the right tile', (WidgetTester t) async {
      final LangPack p = LangPack('rus');
      p.add(
        tapJson(
          course: 'rus',
          id: 'rev',
          scene: <String, Object?>{'optionsOnTiles': true},
          options: <Map<String, Object?>>[
            pictureOption('o1', 'flower_red', reveal: 'роза'),
            pictureOption('o2', 'flower_yellow', tag: p.tag('lis.sem')),
            pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      final Rig r = Rig(p, 'rev', captions: true);
      await r.pump(t);
      expect(opacityOfCaption(t), 0);
      await t.tap(r.tile('o1'));
      await t.pump(const Duration(milliseconds: 400));
      expect(opacityOfCaption(t), 1);
      expect(
        t.getTopLeft(find.byKey(const Key('reveal-caption'))).dy,
        greaterThan(
          t.getRect(find.descendant(of: r.tile('o1'), matching: find.byKey(const Key('answer-tile')))).bottom,
        ),
      );
      await r.done(t);
    });
  });

  group('the caption policy', () {
    test(
      'only the Russian reader route with Band B or C presentation, and never when a parent turned it off',
      () {
        bool on(String course, String? route, int band, {bool off = false}) =>
            captionAfterAnswer(course: course, route: route, presentationBand: band, parentOff: off);
        expect(on('rus', 'reader', 1), isTrue);
        expect(on('rus', 'reader', 2), isTrue);
        expect(on('rus', 'reader', 0), isFalse, reason: 'never under Band A presentation');
        expect(on('rus', 'reader', 2, off: true), isFalse);
        expect(on('rus', 'new', 2), isFalse);
        expect(on('rus', 'heritage', 2), isFalse);
        expect(on('rus', null, 2), isFalse);
        expect(on('eng', 'reader', 2), isFalse);
        expect(on('heb', 'reader', 2), isFalse);
        expect(on('core', 'reader', 2), isFalse);
      },
    );

    test(
      'stress marks: a new learner sees them, a heritage speaker and a reader do not, the parent decides',
      () {
        bool shows(StressMarks s, String? route) => showsStress(setting: s, route: route);
        expect(shows(StressMarks.route, 'new'), isTrue);
        expect(shows(StressMarks.route, null), isTrue);
        expect(shows(StressMarks.route, 'heritage'), isFalse);
        expect(shows(StressMarks.route, 'reader'), isFalse);
        expect(shows(StressMarks.on, 'reader'), isTrue);
        expect(shows(StressMarks.off, 'new'), isFalse);
        expect(withStress('ма${_cp(0x301)}ма', show: false), 'мама');
        expect(withStress('ма${_cp(0x301)}ма', show: true), 'ма${_cp(0x301)}ма');
      },
    );
  });

  group('the layout on the four boards', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('${b.key}: three words, four words and letters fit their row without a fault', (
        WidgetTester t,
      ) async {
        final ActivitySpec spec = ActivitySpec.of(boardClassFor(b.value));
        for (final (String, List<String>, String) c in <(String, List<String>, String)>[
          ('words', <String>['cat', 'dog', 'sun'], 'eng'),
          ('words', <String>['кот', 'дом', 'сон'], 'rus'),
          ('words', <String>['כֶּלֶב', 'חָתוּל', 'סוּס'], 'heb'),
          ('words', <String>['a', 'b', 'c'], 'eng'),
          ('words', <String>['cat', 'dog', 'sun', 'pig'], 'eng'),
          ('words', <String>['кот', 'дом', 'сон', 'нос'], 'rus'),
        ]) {
          final Rig r = Rig(
            words(c.$3, c.$2, id: c.$1, face: c.$2.every((String w) => w.length == 1) ? 'letter' : null),
            c.$1,
          );
          await r.pump(t, size: b.value);
          final List<Rect> tiles = <Rect>[
            for (final String id in <String>[for (int i = 1; i <= c.$2.length; i++) 'o$i'])
              t.getRect(find.descendant(of: r.tile(id), matching: find.byKey(const Key('answer-tile')))),
          ]..sort((Rect p, Rect q) => p.left.compareTo(q.left));
          final double width = TapGeometry.tileWidthOf(r.activity, spec);
          for (final Rect tile in tiles) {
            expect(tile.width, closeTo(width, 0.5), reason: '${b.key} ${c.$3}');
            expect(tile.height, 96);
          }
          for (int i = 0; i + 1 < tiles.length; i++) {
            expect(
              tiles[i].right,
              lessThan(tiles[i + 1].left),
              reason: '${b.key} ${c.$3}: tiles do not touch',
            );
          }
          expect(tiles.first.left, greaterThanOrEqualTo(spec.tilesLeft), reason: b.key);
          expect(tiles.last.right, lessThanOrEqualTo(spec.tilesLeft + spec.tilesWidth), reason: b.key);
          expect(t.takeException(), isNull, reason: '${b.key} ${c.$3}');
          await r.done(t);
        }
      });
    }

    test('the width of a tile: 96 for letters, buttons and pictures; wide for words; the same for the hint\'s geometry', () {
      const ActivitySpec phone = ActivitySpec.phone;
      final TapAnswerActivity w = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words').activity;
      final TapAnswerActivity l = Rig(
        words('eng', <String>['a', 'b', 'c'], face: 'letter'),
        'words',
      ).activity;
      expect(TapGeometry.tileWidthOf(l, phone), 96);
      expect(TapGeometry.tileWidthOf(w, phone), 534 / 3 - 24);
      expect(
        TapGeometry.tileWidthOf(w, ActivitySpec.tabletPortrait),
        220,
        reason: 'a word tile is 220 wide at most',
      );
      const Size stage = Size(330, 128);
      // The row of words is centred on the board's tiles box, as the tiles are, left to right in English.
      final TapGeometry g = TapGeometry(w, stage, phone, dir: TextDirection.ltr);
      expect(g.optionTip(0).dx, lessThan(g.optionTip(1).dx));
      expect(g.optionTip(1).dx - g.optionTip(0).dx, TapGeometry.tileWidthOf(w, phone) + 24);
    });
  });

  group('the tile in the frame', () {
    testWidgets(
      'an AnswerTile is still the tile: the clay lip, the border and the semantics label of the text',
      (WidgetTester t) async {
        final Rig r = Rig(words('eng', <String>['cat', 'dog', 'sun']), 'words');
        await r.pump(t);
        expect(find.byType(AnswerTile), findsNWidgets(3));
        expect(t.getSemantics(r.tile('o1')).label, 'cat');
        await r.done(t);
      },
    );
  });
}
