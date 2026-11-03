// Goldens of LS01 on the four boards, on the lesson screen with the companion, the bubble and the trail: English and Russian
// words on text tiles with their speakers, Hebrew words right to left, sound buttons with a word on show in its chip, and the
// word under the picture after the answer. Fixture course and fake clips, not content. The Hebrew prompts are samples
// (needs-editor), and so are the English and Russian words (for their teachers).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls01_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/language_screens.dart' show langKid;
import 'support/language_voice.dart';
import 'support/voice_fixtures.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

String _cp(int r) => String.fromCharCode(r);

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Set<String> _refs(LangPack p) {
  final Set<String> out = <String>{};
  void scan(Object? n) {
    if (n is String && n.startsWith('vo:')) out.add(n);
    if (n is Map<String, Object?>) n.values.forEach(scan);
    if (n is List<Object?>) n.forEach(scan);
  }

  scan(p.pack.docs);
  return out;
}

/// The lesson of the one activity [id] of [p] on the screen, on a board of [size]. With [route] the child's Russian route is set.
Future<void> _open(WidgetTester t, LangPack p, String id, Size size, {String? route}) async {
  final PackContent content = p.content;
  final AppRig rig = AppRig(
    content: content,
    characters: await languageVoiceSource(_refs(p)),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
  if (route != null) {
    await rig.db.putSetting(
      languagesSettingKey,
      const FamilyLanguages()
          .withSwitches(langKid, 'rus', LanguageSwitches(on: true, route: route))!
          .encode(),
    );
  }
  await rig.pump(t, size: size);
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  final Activity a = content.activities['${p.course}.$id']!;
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(
            profileId: langKid,
            mission: Lesson.mission(
              id: 'shot',
              itemIds: <String>[a.id],
              skillIds: <String>[a.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            ),
          ),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  await _wait(t, 2500);
}

Future<void> _shot(WidgetTester t, String name, String board, {int wait = 600}) async {
  await _wait(t, wait);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ls01_${name}_$board.png'));
}

LangPack _wordsPack(String course, List<String> w, String prompt, {String? face}) {
  final LangPack p = LangPack(course);
  p.add(
    tapJson(
      course: course,
      id: 'words',
      promptText: prompt,
      options: <Map<String, Object?>>[
        for (final (int i, String word) in w.indexed)
          textOption(
            'o${i + 1}',
            word,
            tag: i == 0 ? null : p.tag(i.isOdd ? 'lis.sem' : 'lis.guess'),
            clip: 'vo:$course.words.${'abc'[i]}',
          ),
      ],
      correct: 'o1',
      target: 'vo:$course.words.word',
      answer: <String, Object?>{'face': ?face},
    ),
  );
  return p;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('English words on text tiles, each with its speaker', (WidgetTester t) async {
        await _open(
          t,
          _wordsPack('eng', <String>['cat', 'elephant', 'sun'], 'הַקְשִׁיבוּ, וּגְעוּ בַּמִּלָּה.'),
          'words',
          b.value,
        );
        await _shot(t, 'eng_words', b.key);
      });

      testWidgets('Russian words on text tiles, with their stress marks', (WidgetTester t) async {
        await _open(
          t,
          _wordsPack('rus', <String>[
            'ма${_cp(0x301)}ма',
            'па${_cp(0x301)}па',
            'ба${_cp(0x301)}ба',
          ], 'הַקְשִׁיבוּ, וּגְעוּ בַּמִּלָּה.'),
          'words',
          b.value,
        );
        await _shot(t, 'rus_words', b.key);
      });

      testWidgets('Hebrew words on text tiles, right to left', (WidgetTester t) async {
        await _open(
          t,
          _wordsPack('heb', <String>['כֶּלֶב', 'חָתוּל', 'סוּס'], 'הַקְשִׁיבוּ, וּגְעוּ בַּמִּלָּה.'),
          'words',
          b.value,
        );
        await _shot(t, 'heb_words', b.key);
      });

      testWidgets('letters on square tiles', (WidgetTester t) async {
        await _open(
          t,
          _wordsPack('eng', <String>['b', 'd', 'p'], 'הַקְשִׁיבוּ, וּגְעוּ בָּאוֹת.', face: 'letter'),
          'words',
          b.value,
        );
        await _shot(t, 'eng_letters', b.key);
      });

      testWidgets('sound buttons, and a word on show in its chip under the line', (WidgetTester t) async {
        final LangPack p = LangPack();
        final Map<String, Object?> a = tapJson(
          id: 'snd',
          promptText: 'כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים.',
          options: <Map<String, Object?>>[
            soundOption('o1', 'vo:eng.snd.a'),
            soundOption('o2', 'vo:eng.snd.b', tag: p.tag('lis.numword')),
            soundOption('o3', 'vo:eng.snd.c', tag: p.tag('lis.numword')),
          ],
          correct: 'o1',
        );
        ((a['hints']! as List<Object?>)[1]! as Map<String, Object?>)['show'] = 'three';
        p.add(a);
        await _open(t, p, 'snd', b.value);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await _wait(t, 400);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await _wait(t, 2500);
        await _shot(t, 'sound_chip', b.key);
      });

      testWidgets('count and tap in a course: the scored step, "how many?", on sound buttons', (
        WidgetTester t,
      ) async {
        final LangPack p = LangPack();
        p.add(
          countJson(
            id: 'cnt',
            count: 3,
            clips: <String>['vo:eng.n.one', 'vo:eng.n.two', 'vo:eng.n.three'],
            options: <Map<String, Object?>>[
              soundOption('o1', 'vo:eng.n.three', value: 3),
              soundOption('o2', 'vo:eng.n.two', value: 2, tag: p.tag('lis.numword')),
              soundOption('o3', 'vo:eng.n.four', value: 4, tag: p.tag('lis.numword')),
            ],
            correct: 'o1',
            answerTarget: 'vo:eng.n.howmany',
          ),
        );
        await _open(t, p, 'cnt', b.value);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(Key('butterfly-$i')));
          await _wait(t, 700);
        }
        await _shot(t, 'count_answer', b.key);
      });

      testWidgets('the word under the right picture after the answer (the Russian reader)', (
        WidgetTester t,
      ) async {
        final LangPack p = LangPack('rus');
        p.add(
          tapJson(
            course: 'rus',
            id: 'rev',
            promptText: 'הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה.',
            options: <Map<String, Object?>>[
              pictureOption('o1', 'flower_red', reveal: 'ро${_cp(0x301)}за', clip: 'vo:rus.rev.a'),
              pictureOption('o2', 'flower_yellow', tag: p.tag('lis.sem'), clip: 'vo:rus.rev.b'),
              pictureOption('o3', 'butterfly', tag: p.tag('lis.guess'), clip: 'vo:rus.rev.c'),
            ],
            correct: 'o1',
          ),
        );
        await _open(t, p, 'rev', b.value, route: 'reader');
        await t.tap(find.byKey(const Key('option-o1')));
        // The praise lasts 1.6 seconds, then the lesson ends: the word is shot while it stands under the picture.
        await _shot(t, 'caption', b.key, wait: 500);
      });
    });
  }
}
