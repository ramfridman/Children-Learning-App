// A say-it lesson on the screen for the QA tests of milestone L3: one English item "cat", the parent's voice switches and the fake
// model as asked, a fake recogniser that does what the test scripts. No real voice and no model.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'app_harness.dart';
import 'fake_speech.dart';
import 'language_content.dart';
import 'language_screens.dart' show langKid;
import 'language_voice.dart';
import 'voice_fixtures.dart';

Set<String> qaRefs(LangPack p) {
  final Set<String> out = <String>{};
  void scan(Object? n) {
    if (n is String && n.startsWith('vo:')) out.add(n);
    if (n is Map<String, Object?>) n.values.forEach(scan);
    if (n is List<Object?>) n.forEach(scan);
  }

  scan(p.pack.docs);
  return out;
}

Future<void> qaWait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

/// The say-it items of [items] (default one, `cat1`) on the screen. [voice] is the switch of the child [voiceFor] for the course
/// [voiceCourse]; [installed] says whether the fake model is on the phone; [released] whether the language has passed its release
/// gate (as the voice switch is when not said: the real app has none released); [scored] marks the items as scored listening items.
Future<AppRig> qaOpenSay(
  WidgetTester t, {
  bool voice = true,
  bool installed = true,
  bool? released,
  String voiceFor = langKid,
  String voiceCourse = 'eng',
  int items = 1,
  bool scored = false,
  Size? size,
  List<Scripted> script = const <Scripted>[],
}) async {
  final LangPack p = LangPack();
  for (int i = 1; i <= items; i++) {
    p.add(sayJson(id: 'cat$i', scored: scored));
  }
  final PackContent content = p.content;
  final AppRig rig = AppRig(
    content: content,
    characters: await languageVoiceSource(qaRefs(p)),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
    speech: FakeSpeechEngine(script)..installed = installed,
    sayReleased: (released ?? voice) ? const <String>{'eng'} : const <String>{},
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
  await rig.db.putSetting(
    languagesSettingKey,
    const FamilyLanguages()
        .withSwitches(voiceFor, voiceCourse, LanguageSwitches(on: true, voice: voice))!
        .encode(),
  );
  await (size == null ? rig.pump(t) : rig.pump(t, size: size));
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  final List<String> ids = <String>[
    for (final Activity a in content.activities.values)
      if (a is SayItActivity) a.id,
  ]..sort();
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(
            profileId: langKid,
            mission: Lesson.mission(
              id: 'say',
              itemIds: ids,
              skillIds: <String>[content.activities[ids.first]!.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            ),
          ),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  await qaWait(t, 2500);
  return rig;
}
