import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/theme.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/parent/language_settings.dart';

import 'app_harness.dart';
import 'sample_pack.dart';

/// The child id of the language tests: the shape the family's account takes (the rig's usual `p-1` is too short for it).
const String langKid = 'child-lang-0001';

/// A rig with a child and the given language switches stored for them.
Future<AppRig> langRig({Map<String, LanguageSwitches> languages = const <String, LanguageSwitches>{}}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(id: langKid);
  FamilyLanguages f = const FamilyLanguages();
  for (final MapEntry<String, LanguageSwitches> e in languages.entries) {
    f = f.withSwitches(langKid, e.key, e.value)!;
  }
  if (!f.isEmpty) await rig.db.putSetting(languagesSettingKey, f.encode());
  return rig;
}

Future<Profile> langProfile(AppRig rig) async =>
    (await rig.db.allProfiles()).firstWhere((Profile p) => p.id == langKid);

/// Shows a parent screen on its own, with the rig's providers, on a board of the given size.
Future<void> pumpParentScreen(
  WidgetTester tester,
  AppRig rig,
  Widget screen, {
  Size size = const Size(820, 1180),
  List<Override> extra = const <Override>[],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(rig.db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[...rig.overrides, ...extra],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('he'),
        supportedLocales: const <Locale>[Locale('he')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.parent(),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The English fixture course with strands and a gate, and the child's engine on it (nothing answered yet).
({PackContent content, Engine engine}) englishFixture() {
  final SamplePack p = SamplePack.language('eng');
  p.doc('skill.ENG-A-01.json')['strand'] = 'lis';
  p.doc('skill.ENG-A-02.json')['strand'] = 'rd';
  p.addDocument('gate.eng.oral.json', 'gates', 'eng.oral', <String, Object?>{
    'schema': 'gate/v1',
    'id': 'eng.oral',
    'course': 'eng',
    'requires': <Object?>['ENG-A-01'],
    'holds': <Object?>['ENG-A-02'],
    'neverUnderBand': 0,
    'parentSwitch': <String, Object?>{'name': 'oralOnly', 'effect': 'closes'},
  });
  final PackContent content = PackContent.fromPack(p.verified());
  return (content: content, engine: Engine(catalog: engineCatalog(content)));
}
