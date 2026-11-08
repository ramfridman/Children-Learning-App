// The parent's pages for the languages (docs/design/languages-island.md section 6, texts of docs/languages/island-texts.md): the
// Languages card of a child, a language's page with the switches of frame 1.4, the questionnaire, the progress in a language,
// and the setup question. Nothing on them compares languages, children or days, or counts a streak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/parent/child_form.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/parent/language_progress.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

Future<FamilyLanguages> stored(AppRig rig) async =>
    FamilyLanguages.decode(await rig.db.setting(languagesSettingKey));

/// The progress of the English fixture, made by hand so that every state of the page is on it.
LanguageProgress sample() => const LanguageProgress(
  course: 'eng',
  strands: <StrandProgress>[
    StrandProgress(
      name: He.langStrandEngLisSpk,
      learning: 3,
      understood: 4,
      remembered: 2,
      revisit: 1,
      notStarted: 2,
      startLevel: 2,
    ),
    StrandProgress(
      name: He.langStrandEngPhon,
      learning: 2,
      understood: 3,
      remembered: 0,
      revisit: 0,
      notStarted: 5,
      startLevel: 1,
    ),
    StrandProgress(
      name: He.langStrandEngRead,
      learning: 0,
      understood: 0,
      remembered: 0,
      revisit: 0,
      notStarted: 6,
    ),
    StrandProgress(
      name: He.langStrandEngWrite,
      learning: 1,
      understood: 0,
      remembered: 0,
      revisit: 0,
      notStarted: 4,
    ),
  ],
  gates: <GateView>[GateView(name: He.areaLangGateEng, state: GateState.open)],
  speaking: <SpeakingView>[
    SpeakingView(title: 'מילים', said: false),
    SpeakingView(title: 'ברכות', said: true),
  ],
  notices: <NoticeView>[NoticeView(text: 'מבלבלים בין צלילים דומים', resolved: false)],
);

void main() {
  setUpAll(loadAppFonts);

  group('the Languages card of a child', () {
    testWidgets('a row for each language in the order of the doors, with its state in words and a switch', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: true)},
      );
      await pumpParentScreen(
        tester,
        rig,
        ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
      );
      final List<double> ys = <double>[
        for (final String c in <String>['eng', 'heb', 'rus'])
          tester.getTopLeft(find.byKey(Key('language-row-$c'))).dy,
      ];
      expect(ys[0], lessThan(ys[1]));
      expect(ys[1], lessThan(ys[2]));
      expect(find.text(He.areaLangStateOn.text), findsOneWidget);
      expect(find.text(He.areaLangStateOff.text), findsNWidgets(2));
      expect(tester.widget<Switch>(find.byKey(const Key('language-switch-eng'))).value, isTrue);
      expect(tester.widget<Switch>(find.byKey(const Key('language-switch-heb'))).value, isFalse);
      expect(find.text(He.areaLanguagesHelp.text), findsOneWidget);
    });

    testWidgets(
      'turning a language on or off is saved at once, keeps what else was chosen, and the other languages are untouched',
      (WidgetTester tester) async {
        final AppRig rig = await langRig(
          languages: <String, LanguageSwitches>{
            'eng': const LanguageSwitches(on: true, oralOnly: true),
            'heb': const LanguageSwitches(on: true),
          },
        );
        await pumpParentScreen(
          tester,
          rig,
          ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
        );
        await tester.tap(find.byKey(const Key('language-switch-eng')));
        await tester.pumpAndSettle();
        FamilyLanguages f = await stored(rig);
        expect(f.of(langKid, 'eng').on, isFalse);
        expect(f.of(langKid, 'eng').oralOnly, isTrue, reason: 'turning it off keeps its other choices');
        expect(f.of(langKid, 'heb').on, isTrue);
        expect(f.enabledFor(langKid), <String>['heb']);
        await tester.tap(find.byKey(const Key('language-switch-eng')));
        await tester.pumpAndSettle();
        f = await stored(rig);
        expect(f.enabledFor(langKid), <String>['eng', 'heb']);
      },
    );

    testWidgets(
      'turning Russian on for the first time opens the home-language questionnaire, and an answer is saved as an enum',
      (WidgetTester tester) async {
        final AppRig rig = await langRig();
        await pumpParentScreen(
          tester,
          rig,
          ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
        );
        await tester.tap(find.byKey(const Key('language-switch-rus')));
        await tester.pumpAndSettle();
        expect(find.byType(QuestionnairePage), findsOneWidget);
        await tester.tap(find.byKey(const Key('answer-home-grandparentsOthers')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('answer-reads-sentences')));
        await tester.pumpAndSettle();
        final LanguageSwitches s = (await stored(rig)).of(langKid, 'rus');
        expect(s.on, isTrue);
        expect(s.questionnaire, <String, String>{'home': 'grandparentsOthers', 'reads': 'sentences'});
      },
    );

    testWidgets('the row opens the language page', (WidgetTester tester) async {
      final AppRig rig = await langRig();
      await pumpParentScreen(
        tester,
        rig,
        ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
      );
      await tester.tap(find.byKey(const Key('language-row-heb')));
      await tester.pumpAndSettle();
      expect(find.byType(LanguagePage), findsOneWidget);
    });
  });

  group('a language page', () {
    Future<AppRig> page(WidgetTester tester, String course, {LanguageSwitches? switches}) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{course: switches ?? const LanguageSwitches(on: true)},
        installed: const <String>[], // no course pack is on this phone, as the progress test below expects
      );
      await pumpParentScreen(tester, rig, LanguagePage(profile: await langProfile(rig), course: course));
      return rig;
    }

    testWidgets(
      'English: voice, personal questions, oral only and the band, and none of the other courses\' switches',
      (WidgetTester tester) async {
        await page(tester, 'eng');
        expect(find.byKey(const Key('page-voice')), findsOneWidget);
        expect(find.byKey(const Key('page-personal')), findsOneWidget);
        expect(find.byKey(const Key('page-oral-only')), findsOneWidget);
        expect(find.byKey(const Key('band-age')), findsOneWidget);
        expect(find.byKey(const Key('page-letters5')), findsNothing);
        expect(find.byKey(const Key('page-read-check')), findsNothing);
        expect(find.byKey(const Key('open-questionnaire')), findsNothing);
      },
    );

    testWidgets('Russian: letters before 5, stress marks with the route, the questionnaire', (
      WidgetTester tester,
    ) async {
      await page(tester, 'rus');
      expect(find.byKey(const Key('page-letters5')), findsOneWidget);
      expect(find.byKey(const Key('stress-route')), findsOneWidget);
      expect(find.byKey(const Key('route-heritage')), findsOneWidget);
      expect(find.byKey(const Key('open-questionnaire')), findsOneWidget);
      expect(find.byKey(const Key('page-oral-only')), findsNothing);
      expect(find.text(He.areaLangLettersOff.text), findsOneWidget);
    });

    testWidgets(
      'Hebrew: the parent check of reading aloud, and the voice line without the download sentence',
      (WidgetTester tester) async {
        await page(tester, 'heb');
        expect(find.byKey(const Key('page-read-check')), findsOneWidget);
        expect(find.text(He.areaLangVoiceHelpHeb.text), findsOneWidget);
        expect(find.byKey(const Key('page-oral-only')), findsNothing);
      },
    );

    testWidgets(
      'every switch is saved as the parent set it, and the voice is off, the personal questions on, until then',
      (WidgetTester tester) async {
        final AppRig rig = await page(tester, 'rus');
        expect(
          tester
              .widget<Switch>(
                find.descendant(of: find.byKey(const Key('page-voice')), matching: find.byType(Switch)),
              )
              .value,
          isFalse,
        );
        expect(
          tester
              .widget<Switch>(
                find.descendant(of: find.byKey(const Key('page-personal')), matching: find.byType(Switch)),
              )
              .value,
          isTrue,
        );
        await tester.tap(
          find.descendant(of: find.byKey(const Key('page-voice')), matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: find.byKey(const Key('page-personal')), matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: find.byKey(const Key('page-letters5')), matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('stress-off')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('route-heritage')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('band-0')));
        await tester.pumpAndSettle();
        final LanguageSwitches s = (await stored(rig)).of(langKid, 'rus');
        expect(
          <Object?>[s.voice, s.personal, s.lettersBefore5, s.stress, s.route, s.band],
          <Object?>[true, false, true, StressMarks.off, 'heritage', 0],
        );
        // Choosing the age again clears the parent's band.
        await tester.tap(find.byKey(const Key('band-age')));
        await tester.pumpAndSettle();
        expect((await stored(rig)).of(langKid, 'rus').band, isNull);
      },
    );

    testWidgets('the page is titled with the language and the child, and has a way to the progress', (
      WidgetTester tester,
    ) async {
      await page(tester, 'eng');
      expect(find.textContaining('${He.langEnglish.text} ·'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-language-progress')));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageProgressPage), findsOneWidget);
      expect(
        find.byKey(const Key('progress-no-course')),
        findsOneWidget,
        reason: 'no English pack is installed here',
      );
    });
  });

  group('the progress in a language', () {
    testWidgets(
      'by strand, with the words and counts under every bar, the gates, speaking as practised or said, and what to notice',
      (WidgetTester tester) async {
        final AppRig rig = await langRig(
          languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: true)},
        );
        await pumpParentScreen(
          tester,
          rig,
          LanguageProgressPage(profile: await langProfile(rig), course: 'eng'),
          extra: <Override>[
            languageProgressProvider.overrideWith(
              (Ref ref, ({String childId, String course}) key) async => sample(),
            ),
          ],
        );
        for (final String s in <String>[
          He.langStrandEngLisSpk.text,
          He.langStrandEngPhon.text,
          He.langStrandEngRead.text,
          He.langStrandEngWrite.text,
        ]) {
          expect(find.text(s), findsOneWidget, reason: s);
        }
        expect(
          find.text(
            '${He.statusPractising.text} 3 · ${He.statusUnderstood.text} 4 · ${He.statusRemembered.text} 2 · ${He.statusRevisit.text} 1',
          ),
          findsOneWidget,
        );
        expect(find.text(He.progressNotYetPlayed.text), findsOneWidget, reason: 'a strand not begun says so');
        expect(find.text(He.areaLangStrandStart.fill(<String, String>{'n': '2'})), findsOneWidget);
        expect(find.text(He.areaLangGateEng.text), findsOneWidget);
        expect(find.text(He.areaLangGateChipOpen.text), findsOneWidget);
        expect(find.text(He.areaLangPractised.text), findsOneWidget);
        expect(find.text(He.areaLangSaid.text), findsOneWidget);
        expect(find.text(He.areaLangSpeakingHelp.text), findsOneWidget);
        expect(find.text('מבלבלים בין צלילים דומים'), findsOneWidget);
      },
    );

    testWidgets(
      'never a streak, a day count, a "you have not practised", or a language, child or day beside another',
      (WidgetTester tester) async {
        final AppRig rig = await langRig(
          languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: true)},
        );
        await pumpParentScreen(
          tester,
          rig,
          LanguageProgressPage(profile: await langProfile(rig), course: 'eng'),
          extra: <Override>[
            languageProgressProvider.overrideWith(
              (Ref ref, ({String childId, String course}) key) async => sample(),
            ),
          ],
        );
        final String all = <String>[
          for (final Text t in tester.widgetList<Text>(find.byType(Text)))
            if (t.data != null) t.data!,
        ].join(' ');
        for (final String banned in <String>['ברצף', 'לא תרגלו', 'לא שיחקו', 'ימים', 'דקות', 'streak']) {
          expect(all.contains(banned), isFalse, reason: banned);
        }
        expect(
          find.byType(CustomPaint).evaluate().length,
          lessThan(40),
          reason: 'no chart of one language beside another',
        );
      },
    );

    test('the page is built from the pack and the child\'s engine: counts by strand, a gate that is not yet open', () {
      final fixture = englishFixture();
      fixture.engine.apply(
        AttemptEvent(
          at: DateTime.utc(2026, 11, 3, 9),
          activityId: 'eng.count.butterflies.3',
          result: Result.correct,
          course: 'eng',
        ),
      );
      final LanguageProgress p = buildLanguageProgress(
        content: fixture.content,
        engine: fixture.engine,
        now: DateTime.utc(2026, 11, 3, 10),
        switches: const LanguageSwitches(on: true),
        ageBand: 1,
      );
      expect(p.strands.map((StrandProgress s) => s.name.text), <String>[
        He.langStrandEngLisSpk.text,
        He.langStrandEngRead.text,
      ]);
      expect(p.strands.first.learning, 1);
      expect(p.strands.last.notStarted, 1);
      expect(p.gates.single.state, GateState.notYet);
      // "Oral only" holds it closed, and says that the parent did.
      final LanguageProgress held = buildLanguageProgress(
        content: fixture.content,
        engine: fixture.engine,
        now: DateTime.utc(2026, 11, 3, 10),
        switches: const LanguageSwitches(on: true, oralOnly: true),
        ageBand: 1,
      );
      expect(held.gates.single.state, GateState.closedByParent);
    });
  });

  group('the setup question (Q-F1)', () {
    testWidgets(
      'all three languages are ticked at first, with a line each; unticking one leaves it without a door',
      (WidgetTester tester) async {
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup(id: langKid);
        await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 1700));
        for (final String c in <String>['eng', 'heb', 'rus']) {
          expect(
            tester.widget<CheckboxListTile>(find.byKey(Key('setup-language-$c'))).value,
            isTrue,
            reason: c,
          );
        }
        expect(find.text(He.langSetupEnglish.text), findsOneWidget);
        await tester.tap(find.byKey(const Key('setup-language-rus')));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'דנה');
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('stage-gan5')));
        await tester.tap(find.byKey(const Key('stage-gan5')));
        await tester.pump();
        await tester.tap(find.text(He.setupSave.text));
        await tester.pumpAndSettle();
        final List<Profile> kids = await rig.db.allProfiles();
        final String newId = kids.firstWhere((Profile p) => p.id != langKid).id;
        expect((await stored(rig)).enabledFor(newId), <String>['eng', 'heb']);
      },
    );
  });
}
