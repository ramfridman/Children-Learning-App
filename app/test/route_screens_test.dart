// The Russian routes on the lesson screen (docs/languages/band-a-build.md 2.6.1, R3 and R4), with the real Band A pack and fake clips:
//  * the hearing screen of A-20 (a heritage speaker): the line and the word once, no microphone, no "I said it", the picture after the word,
//    the word again on the replay button, nothing written;
//  * the say step picture first: the question alone, the pause, then the word (no chip: Band A has no reading); the microphone and "I said it" from the start;
//    echo for a new learner (and a reader the placement has not put past its first level);
//  * the pictures of batch 6: the rooms of RUS-A-13 as a listen-and-do, the heart and the flower cards of Hebrew A-10.
//
// To look at them: `NN_SHOTS=<folder> flutter test test/route_screens_test.dart` writes a picture of each screen on the phone and the tablet.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/template_session.dart' show PackSvg;

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_golden.dart' show boards, waitFor;
import 'support/language_screens.dart' show langKid;
import 'support/language_voice.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const String _languages = '../content/languages';

/// Writes the picture of a screen to a folder instead of comparing it.
class _Shots extends GoldenFileComparator {
  _Shots(this.folder);

  final Directory folder;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    File('${folder.path}${Platform.pathSeparator}${golden.pathSegments.last}').writeAsBytesSync(imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) => compare(imageBytes, golden);
}

Set<String> _refs(Object? n) {
  final Set<String> out = <String>{};
  void scan(Object? x) {
    if (x is String && x.startsWith('vo:')) out.add(x);
    if (x is Map<String, Object?>) x.values.forEach(scan);
    if (x is List<Object?>) x.forEach(scan);
  }

  scan(n);
  return out;
}

class _Course {
  _Course(this.course, this.pack) : content = PackContent.fromPack(pack);

  final String course;
  final VerifiedPack pack;
  final PackContent content;
}

Finder get _mic => find.byKey(const Key('lesson-mic'));
Finder get _done => find.byKey(const Key('say-done'));
Finder get _picture => find.byKey(const Key('say-picture'));
Finder get _drawn => find.descendant(of: _picture, matching: find.byType(PackSvg));

void main() {
  final String? shots = Platform.environment['NN_SHOTS'];
  late _Course rus;
  late _Course heb;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    if (shots != null) {
      Directory(shots).createSync(recursive: true);
      goldenFileComparator = _Shots(Directory(shots));
    }
    final PackKey key = await newTestKey();
    Future<_Course> build(String course) async => _Course(
      course,
      await verifyPack(
        (await buildPack(languageSource(course, _languages), key)).bytes,
        publicKey: key.publicKey,
      ),
    );
    rus = await build('rus');
    heb = await build('heb');
  });

  /// A lesson of [c] on the screen: the lesson [lessonId] of the pack, or a one-step lesson of the activity [activity]. [route] is the
  /// parent's route for the child; [voice] puts the microphone on (the model is the fake one).
  Future<AppRig> open(
    WidgetTester t,
    _Course c, {
    String? lessonId,
    String? activity,
    String? route,
    bool voice = false,
    Size? size,
    int settle = 500,
  }) async {
    final Activity? a = activity == null ? null : c.content.activities[activity];
    final AppRig rig = AppRig(
      content: c.content,
      characters: await languageVoiceSource(_refs(c.pack.docs)),
      player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
      speech: FakeSpeechEngine()..installed = true,
      sayReleased: <String>{c.course},
    )..languagePacks = <String, PackContent>{c.course: c.content};
    await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
    await rig.db.putSetting(
      languagesSettingKey,
      const FamilyLanguages()
          .withSwitches(langKid, c.course, LanguageSwitches(on: true, route: route, voice: voice))!
          .encode(),
    );
    await (size == null ? rig.pump(t) : rig.pump(t, size: size));
    await t.tap(find.text('נֹעָה'));
    await t.pumpAndSettle();
    t
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext x) => LessonScreen(
              profileId: langKid,
              course: c.course,
              lessonId: lessonId ?? 'butterflies',
              mission: a == null
                  ? null
                  : Lesson.mission(
                      id: 'route',
                      itemIds: <String>[a.id],
                      skillIds: <String>[a.skillId],
                      celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
                    ),
            ),
          ),
        );
    await t.pump(const Duration(milliseconds: 100));
    await waitFor(t, settle);
    expect(t.takeException(), isNull);
    return rig;
  }

  Future<void> shot(WidgetTester t, String name) async {
    if (shots == null) return;
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));
  }

  List<String> lines(AppRig rig) => playedLines(rig.player.played);
  int times(AppRig rig, String line) => lines(rig).where((String l) => l == line).length;

  group('a hearing screen (R3)', () {
    testWidgets(
      'the line and the word once, no microphone, no "I said it", the picture after the word, the replay says the word again',
      (WidgetTester t) async {
        final AppRig rig = await open(
          t,
          rus,
          lessonId: 'rus.pairs-1',
          route: 'heritage',
          voice: true,
          settle: 100,
        );
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(lines(rig).first, 'rus.f41');
        expect(_drawn, findsNothing, reason: 'the picture waits for the word');
        await waitFor(t, 1500);
        expect(lines(rig), <String>['rus.f41', 'rus.mp_luk']);
        expect(_drawn, findsOneWidget, reason: 'the word has been said: the picture is on');
        expect(_mic, findsNothing, reason: 'a hearing screen has no microphone, even with the voice on');
        expect(_done, findsNothing, reason: 'and no "I said it"');
        await waitFor(t, 4000);
        expect(times(rig, 'rus.mp_luk'), 1, reason: 'no second hearing after a pause');
        expect(rig.speech.listens, 0);
        await t.tap(find.byKey(const Key('lesson-replay')));
        await waitFor(t, 600);
        expect(times(rig, 'rus.mp_luk'), 2, reason: 'a replay is free, and the child asks for it');
        expect(await rig.db.attemptsOf(langKid), isEmpty);
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('a touch on the picture goes on to the next hearing screen, and nothing is written', (
      WidgetTester t,
    ) async {
      final AppRig rig = await open(t, rus, lessonId: 'rus.pairs-1', route: 'heritage', settle: 1500);
      await t.tap(_picture);
      await waitFor(t, 1500);
      expect(lines(rig).skip(2).take(2), <String>[
        'rus.f41',
        'rus.mp_ljuk',
      ], reason: 'the second word of the four');
      expect(await rig.db.attemptsOf(langKid), isEmpty);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a new learner is shown teach screens in the same lesson, not hearing screens', (
      WidgetTester t,
    ) async {
      final AppRig rig = await open(t, rus, lessonId: 'rus.pairs-1', route: 'new', settle: 800);
      expect(lines(rig).first, 'rus.f03', reason: 'a teach screen says "let\'s say it together" first');
      expect(lines(rig), isNot(contains('rus.f41')));
      await t.pumpWidget(const SizedBox());
    });

    for (final MapEntry<String, Size> b in boards.entries.where(
      (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'tabletLandscape',
    )) {
      testWidgets('on the ${b.key} board, before the word and after it', (WidgetTester t) async {
        await open(t, rus, lessonId: 'rus.pairs-1', route: 'heritage', size: b.value, settle: 100);
        await shot(t, 'rus_hear_before_${b.key}');
        await waitFor(t, 1500);
        expect(_drawn, findsOneWidget);
        await shot(t, 'rus_hear_${b.key}');
        await t.pumpWidget(const SizedBox());
      });
    }
  });

  group('the say step picture first (R4)', () {
    testWidgets(
      'a heritage speaker: the question alone, the microphone and "I said it" from the start, the word after the pause, and no chip: Band A has no reading',
      (WidgetTester t) async {
        final AppRig rig = await open(
          t,
          rus,
          activity: 'rus.a15.01',
          route: 'heritage',
          voice: true,
          settle: 600,
        );
        expect(lines(rig), <String>['rus.f06'], reason: 'the question alone: it gives no clip, so no word');
        expect(_mic, findsOneWidget);
        expect(_done, findsOneWidget);
        expect(find.text('мама'), findsNothing, reason: 'the word is not on show before the child has tried');
        await waitFor(t, 2500);
        expect(lines(rig), <String>[
          'rus.f06',
        ], reason: 'the pause is the child\'s: it starts when the question has ended');
        await waitFor(t, 2000);
        expect(lines(rig), <String>[
          'rus.f06',
          'rus.w_mama',
        ], reason: 'after the pause the voice says the word');
        expect(
          find.text('мама'),
          findsNothing,
          reason: 'and no chip shows it: a Band A step prints no word (band-a-build.md 7.2)',
        );
        expect(_mic, findsOneWidget);
        expect(rig.speech.listens, 0, reason: 'only a tap opens the microphone');
        expect(await rig.db.attemptsOf(langKid), isEmpty);
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('"I said it" does not stop the word, and the picture then goes on', (WidgetTester t) async {
      final AppRig rig = await open(t, rus, activity: 'rus.a15.01', route: 'heritage', settle: 600);
      await t.tap(_done);
      await waitFor(t, 4500);
      expect(lines(rig), <String>['rus.f06', 'rus.w_mama'], reason: 'the child has still not heard the word');
      await t.tap(_picture);
      await waitFor(t, 2500);
      expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
      expect(await rig.db.attemptsOf(langKid), isEmpty);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
      'A-15 is picture first for a new learner too; after a puppet\'s bubble a heritage speaker is asked f07',
      (WidgetTester t) async {
        final AppRig fresh = await open(t, rus, activity: 'rus.a15.01', route: 'new', settle: 600);
        expect(lines(fresh), <String>['rus.f06']);
        await t.pumpWidget(const SizedBox());
        final AppRig heritage = await open(t, rus, activity: 'rus.a01.04s', route: 'heritage', settle: 600);
        expect(lines(heritage), <String>['rus.f07']);
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'a new learner on A-01 and a reader the placement has not moved are echo: "together" and the word, the word again after the pause',
      (WidgetTester t) async {
        for (final String route in <String>['new', 'reader']) {
          final AppRig rig = await open(t, rus, activity: 'rus.a01.04s', route: route, settle: 600);
          expect(lines(rig), <String>['rus.f03', 'rus.w_privet'], reason: route);
          expect(
            find.text('Привет'),
            findsNothing,
            reason: '$route: the word is heard, not shown (no chip in Band A)',
          );
          await waitFor(t, 3600);
          expect(times(rig, 'rus.w_privet'), 2, reason: route);
          await t.pumpWidget(const SizedBox());
        }
      },
    );

    for (final MapEntry<String, Size> b in boards.entries.where(
      (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'tabletLandscape',
    )) {
      testWidgets('on the ${b.key} board, a heritage speaker on A-15 before and after the word', (
        WidgetTester t,
      ) async {
        await open(
          t,
          rus,
          activity: 'rus.a15.05',
          route: 'heritage',
          voice: true,
          size: b.value,
          settle: 600,
        );
        await shot(t, 'rus_say_heritage_ask_${b.key}');
        await waitFor(t, 4500);
        await shot(t, 'rus_say_heritage_word_${b.key}');
        await t.pumpWidget(const SizedBox());
      });
    }
  });

  group('the pictures of batch 6', () {
    for (final MapEntry<String, Size> b in boards.entries.where(
      (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'tabletLandscape',
    )) {
      testWidgets('the five rooms and the garden of RUS-A-13 are a listen-and-do on the ${b.key} board', (
        WidgetTester t,
      ) async {
        for (final String n in <String>['01', '02', '03', '04', '05', '06']) {
          final Activity a = rus.content.activities['rus.a13.$n']!;
          expect(a.template, 'listen_do', reason: n);
          await open(t, rus, activity: a.id, route: 'new', size: b.value, settle: 700);
          expect(find.byType(LessonScreen), findsOneWidget, reason: n);
          await shot(t, 'rus_a13_${n}_${b.key}');
          await t.pumpWidget(const SizedBox());
        }
      });

      testWidgets('the heart and the flower cards of Hebrew A-10 on the ${b.key} board', (
        WidgetTester t,
      ) async {
        for (final String id in <String>['heb.a10.t05', 'heb.a10.s06']) {
          expect(heb.content.activities[id], isNotNull, reason: id);
          await open(t, heb, activity: id, size: b.value, settle: 700);
          expect(find.byType(LessonScreen), findsOneWidget, reason: id);
          await shot(t, '${id.replaceAll('.', '_')}_${b.key}');
          await t.pumpWidget(const SizedBox());
        }
      });
    }

    test('A-13 items 01 to 06 keep their tags, and the right answer is the first option', () {
      final Map<String, List<String>> tags = <String, List<String>>{
        '01': <String>['rus.lis.sem', 'rus.lis.sem'],
        '02': <String>['rus.lis.sem', 'rus.voc.sound'],
        '03': <String>['rus.voc.sound', 'rus.lis.sem'],
        '04': <String>['rus.voc.sound', 'rus.lis.sem'],
        '05': <String>['rus.voc.sound', 'rus.lis.sem'],
        '06': <String>['rus.voc.sound', 'rus.lis.sem'],
      };
      for (final MapEntry<String, List<String>> e in tags.entries) {
        final ListenDoActivity a = rus.content.activities['rus.a13.${e.key}']! as ListenDoActivity;
        expect(
          <String?>[for (final ChoiceOption o in a.options.skip(1)) o.misconception],
          e.value,
          reason: e.key,
        );
        expect(a.correctId, a.options.first.id, reason: e.key);
      }
    });
  });
}
