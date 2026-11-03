// QA of L0 (docs/qa/l0-languages-verification.md): the rules that must never break, as tests over the Languages screens and
// texts. No streak, guilt or comparison in the parent's pages or the child's door screen; no network, no microphone and no sound
// recording reachable from them; the voice switch only stores the parent's choice; a door screen with nothing on it that counts;
// and a child whose parent turned nothing on keeps today's 7-land map even when a sibling has languages.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/parent/language_settings.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

/// The keys of the Languages strings in `he.dart` (the door, the bottle's lines, the parent's pages, the questionnaire, the
/// setup question) and the text each one holds.
Map<String, String> languageStrings() {
  final String src = File('lib/strings/he.dart').readAsStringSync();
  final RegExp key = RegExp(
    r'static const Str (areaLang\w*|areaLanguages\w*|lang[A-Z]\w*|adventureLang\w*|languagesDoors\w*|hello\w+|childSettingsTitle|'
    r'q(?:KnowsLetters|Home|Understands|Speaks|Letters|Reads)|doorsSemantics|courseHomeSemantics|stressDefault\w*|route[A-Z]\w*|'
    r'statusRemembered) = Str\(([^;]*?)\);',
    dotAll: true,
  );
  final RegExp literal = RegExp(r"'((?:[^'\\]|\\.)*)'");
  return <String, String>{
    for (final RegExpMatch m in key.allMatches(src))
      m.group(1)!: literal.allMatches(m.group(2)!).map((RegExpMatch l) => l.group(1)!).join(' '),
  };
}

void main() {
  setUpAll(loadAppFonts);

  group('no streaks, guilt, comparison or time chart in what a parent or a child reads about a language', () {
    // Hebrew stems of a streak, of "you did not practise", of falling behind and of ranking. (The sentence that says there is no
    // comparison, "אין השוואה ...", is the editor's and is allowed: it names the thing to deny it.)
    final RegExp banned = RegExp(
      'רצף|ברציפות|לא תרגל|לא שיחק|לא למד|פספס|פיגור|מאחור|דירוג|מקום ראשון|שיא|מצטיין|ניקוד|נקודות|טיימר|ספירה לאחור|הזמן שנותר',
    );

    test('the strings of the Languages screens', () {
      final Map<String, String> all = languageStrings();
      expect(all.length, greaterThanOrEqualTo(90), reason: 'the strings were found: ${all.length}');
      for (final MapEntry<String, String> e in all.entries) {
        expect(banned.hasMatch(e.value), isFalse, reason: '${e.key}: ${e.value}');
      }
    });

    test('the sources of the Languages screens name no streak, comparison, ranking or timer', () {
      final RegExp words = RegExp(
        r'streak|daysInARow|inARow|sibling|leaderboard|ranking|\bcompare\b|comparison|countdown|Timer\(|Timer\.|Stopwatch',
        caseSensitive: false,
      );
      for (final String path in <String>[
        'lib/child/languages_doors.dart',
        'lib/parent/language_pages.dart',
        'lib/parent/language_progress.dart',
        'lib/parent/language_settings.dart',
        'lib/app/language_providers.dart',
      ]) {
        for (final String line in File(path).readAsLinesSync()) {
          final String t = line.trimLeft();
          if (t.startsWith('//')) continue;
          expect(words.hasMatch(line), isFalse, reason: '$path: $line');
        }
      }
    });
  });

  group('nothing reachable from the Languages screens leaves the phone or opens the microphone', () {
    test('they import no network, no sound recording and no speech package', () {
      final RegExp imports = RegExp(
        r'''import\s+['"](package:(http|dio|supabase|record|permission_handler|sherpa_onnx|just_audio|audioplayers)[^'"]*|dart:io|dart:html)['"]''',
      );
      for (final String path in <String>[
        'lib/child/languages_doors.dart',
        'lib/parent/language_pages.dart',
        'lib/parent/language_progress.dart',
        'lib/parent/language_settings.dart',
        'lib/app/language_providers.dart',
      ]) {
        final String src = File(path).readAsStringSync();
        expect(imports.hasMatch(src), isFalse, reason: path);
        expect(src.contains('speechEngineProvider'), isFalse, reason: '$path reaches for the recogniser');
        expect(src.contains('requestPermission'), isFalse, reason: '$path asks for the microphone');
      }
    });

    testWidgets(
      'turning the voice switch of a language on only stores the choice: no recogniser, no permission',
      (WidgetTester tester) async {
        final AppRig rig = await langRig(
          languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: true)},
        );
        await pumpParentScreen(
          tester,
          rig,
          LanguagePage(profile: await langProfile(rig), course: 'eng'),
          size: const Size(852, 1100),
        );
        await tester.tap(
          find.descendant(of: find.byKey(const Key('page-voice')), matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        final FamilyLanguages f = FamilyLanguages.decode(await rig.db.setting(languagesSettingKey));
        expect(f.of(langKid, 'eng').voice, isTrue);
        expect(rig.speech.log, isEmpty, reason: 'the model is not prepared, nothing listens');
        expect(<int>[rig.speech.prepares, rig.speech.listens], <int>[0, 0]);
        expect(rig.speech.micOpen, isFalse);
      },
    );
  });

  group('every language off, or on for a sibling only: today\'s map', () {
    testWidgets('a child with no language gets the 7-land map even when a sibling has all three on', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig()..installedLanguages = <String>['eng', 'heb', 'rus'];
      await rig.seedFinishedSetup(id: langKid, name: 'נועה');
      await rig.db.addProfile(
        ProfilesCompanion.insert(
          id: 'child-lang-0002',
          name: 'דנה',
          avatar: 'avatar-noa',
          addressForm: 'f',
          ageBand: 1,
          createdAt: DateTime.utc(2026, 10, 26),
        ),
      );
      FamilyLanguages f = const FamilyLanguages();
      for (final String c in <String>['eng', 'heb', 'rus']) {
        f = f.withSwitches(langKid, c, const LanguageSwitches(on: true))!;
      }
      await rig.db.putSetting(languagesSettingKey, f.encode());
      await rig.pump(tester);
      await tester.tap(find.text('דנה'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byKey(const Key('sign-languages')),
        findsNothing,
        reason: 'no language is on for this child',
      );
      expect(find.byKey(const PageStorageKey<String>('home-map')), findsOneWidget);
      expect(find.byKey(const PageStorageKey<String>('home-map-lang')), findsNothing);
    });
  });
}
