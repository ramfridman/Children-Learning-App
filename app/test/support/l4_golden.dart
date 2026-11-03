// The lesson screen with the companion, the bubble and the trail, opened on one activity of a fixture language pack, for the goldens of
// the Band A templates (L4) on the four boards. Fake clips, the approved pictures of `content/languages/pictures`; not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'app_harness.dart';
import 'language_content.dart';
import 'language_screens.dart' show langKid;
import 'language_voice.dart';
import 'voice_fixtures.dart';

export 'l4_rig.dart' show boards;

/// Every `vo:` reference of the pack's documents.
Set<String> voRefsOf(LangPack p) {
  final Set<String> out = <String>{};
  void scan(Object? n) {
    if (n is String && n.startsWith('vo:')) out.add(n);
    if (n is Map<String, Object?>) n.values.forEach(scan);
    if (n is List<Object?>) n.forEach(scan);
  }

  scan(p.pack.docs);
  return out;
}

Future<void> waitFor(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

/// The lesson of the activity [id] of [p] on the screen, on a board of [size]. [personal] is the parent's switch for personal turns;
/// [flow] is an adaptive visit (the placement game).
Future<AppRig> openLesson(
  WidgetTester t,
  LangPack p,
  String id,
  Size size, {
  bool personal = true,
  ItemFlow? flow,
  List<String>? itemIds,
  int settle = 2500,
}) async {
  final PackContent content = p.content;
  final AppRig rig = AppRig(
    content: content,
    characters: await languageVoiceSource(voRefsOf(p)),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
  if (!personal) {
    await rig.db.putSetting(
      languagesSettingKey,
      const FamilyLanguages()
          .withSwitches(langKid, p.course, const LanguageSwitches(on: true, personal: false))!
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
            flow: flow,
            mission: Lesson.mission(
              id: 'shot',
              itemIds: itemIds ?? <String>[a.id],
              skillIds: <String>[a.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            ),
          ),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  await waitFor(t, settle);
  return rig;
}

Future<void> shot(WidgetTester t, String name, String board, {int wait = 600}) async {
  await waitFor(t, wait);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_$board.png'));
}
