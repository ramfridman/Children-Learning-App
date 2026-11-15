// A lesson of a real course (English lesson 1 `eng.greet-1` by default) on the screen for the tests of step L7-4: the Meet screens and the Find. The pack is built
// from the course's source with a test key, every clip it names is a fake recording, and the player ends each line 150 ms after it starts, so
// that lines wait for each other as they do on a phone.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import '../../tool/pack_builder_lib.dart';
import 'app_harness.dart';
import 'fake_speech.dart';
import 'language_screens.dart' show langKid;
import 'language_voice.dart';
import 'meet_opener.dart';
import 'pack_fixtures.dart';
import 'voice_fixtures.dart';

const String _languages = '../content/languages';

/// The real pack of a course, built with a test key.
Future<PackContent> buildCourse(String course) async {
  final PackKey key = await newTestKey();
  final Uint8List bytes = (await buildPack(languageSource(course, _languages), key)).bytes;
  return PackContent.fromPack(await verifyPack(bytes, publicKey: key.publicKey));
}

/// The real English pack, built with a test key.
Future<PackContent> buildEnglish() => buildCourse('eng');

/// Every `vo:` reference of a course's source (what the fake voice has a recording for).
Set<String> courseRefs(String course) {
  final RegExp ref = RegExp(r'vo:[a-z0-9_.]+');
  final Set<String> out = <String>{};
  for (final FileSystemEntity e in languageSource(course, _languages).listSync()) {
    if (e is File && e.path.endsWith('.json')) {
      out.addAll(ref.allMatches(e.readAsStringSync()).map((RegExpMatch m) => m.group(0)!));
    }
  }
  return out;
}

Set<String> englishRefs() => courseRefs('eng');

class L7Rig {
  L7Rig(this.rig, this.player);

  final AppRig rig;
  final FakePlayer player;

  /// The clips that have been said, in order, as `eng.en_hello`.
  List<String> get said => playedLines(player.played);
}

/// Opens lesson [lesson] of the English pack for a child whose look is [band] (0 youngest), with the parent's voice switch as [voice] says.
Future<L7Rig> openEnglishLesson(
  WidgetTester t,
  PackContent eng, {
  String lesson = 'eng.greet-1',
  Size size = const Size(852, 393),
  int band = 0,
  bool voice = false,
  List<Scripted> script = const <Scripted>[],
  bool reduceMotion = true,
  bool lettersOpen = false,
  bool pastOpener = true,
}) => openCourseLesson(
  t,
  'eng',
  eng,
  lesson: lesson,
  size: size,
  band: band,
  voice: voice,
  script: script,
  reduceMotion: reduceMotion,
  lettersOpen: lettersOpen,
  pastOpener: pastOpener,
);

/// Opens lesson [lesson] of the pack of [course] for a child whose look is [band] (0 youngest), with the parent's voice switch as [voice] says.
/// A lesson that begins with a Meet set is returned at the first word's first beat, the opener said ([pastOpener]).
Future<L7Rig> openCourseLesson(
  WidgetTester t,
  String course,
  PackContent pack, {
  required String lesson,
  Size size = const Size(852, 393),
  int band = 0,
  bool voice = false,
  List<Scripted> script = const <Scripted>[],
  bool reduceMotion = true,
  bool lettersOpen = false,
  bool pastOpener = true,
}) async {
  final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 150);
  final AppRig rig = AppRig(
    characters: await languageVoiceSource(courseRefs(course)),
    player: player,
    speech: FakeSpeechEngine(script)..installed = true,
    sayReleased: voice ? <String>{course} : const <String>{},
    extraOverrides: <Override>[
      meetLettersOpenProvider.overrideWithValue((String childId, String c) => lettersOpen),
    ],
  )..languagePacks = <String, PackContent>{course: pack};
  await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
  await rig.db.putSetting(
    languagesSettingKey,
    const FamilyLanguages()
        .withSwitches(langKid, course, LanguageSwitches(on: true, voice: voice, band: band))!
        .encode(),
  );
  await rig.pump(t, size: size, reduceMotion: reduceMotion);
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(profileId: langKid, lessonId: lesson, course: course),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  // A lesson that opens on a Meet set says its opener first; the tests below count from the word's first beat (pastOpener: false keeps the opener).
  if (pastOpener && openerScreenOf(pack, lesson) != null) await untilWordBeat(t);
  return L7Rig(rig, player);
}

/// Lets [ms] pass in steps of 100 ms (a lesson with a guide cannot settle).
Future<void> l7Wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}
