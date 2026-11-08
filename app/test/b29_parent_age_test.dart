// B-29 step 5b: the parent area's age settings. AgeFields (month, year, school stage), the child form, the child's age page, the settings
// cards (age summary, the look, the captions), the September card and the "add the age" card, and the child row's settings button.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/profile_age.dart';
import 'package:nitznutz/design/components.dart' show ParentButton;
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/age_fields.dart';
import 'package:nitznutz/parent/age_page.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/parent/child_form.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/parent/look_settings.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

/// The rig's clock is 2026-10-26: the school year 2026 (it began on 1 September), so a child born in 2021 is in gan hova.
Future<AppRig> _rig({int band = 1, SchoolStage? stage, BirthMonth? birth}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(id: langKid, ageBand: band);
  if (stage != null) await rig.db.confirmStage(langKid, stage, DateTime.utc(2026, 10, 26));
  if (birth != null) await rig.db.setBirth(langKid, birth);
  return rig;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
}

/// A chosen chip shows a check (never colour alone).
bool _selected(WidgetTester tester, Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byIcon(Icons.check_rounded)).evaluate().isNotEmpty;

bool _enabled(WidgetTester tester, Key key) => tester.widget<ParentButton>(find.byKey(key)).onPressed != null;

void main() {
  setUpAll(loadAppFonts);

  group('AgeFields', () {
    AgeValue value = const AgeValue();
    final DateTime now = DateTime(2026, 10, 26);

    Future<void> pump(WidgetTester tester, {bool suggest = true, SchoolStage? current, int? band}) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('he'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext c, StateSetter set) => SingleChildScrollView(
                  child: AgeFields(
                    value: value,
                    now: now,
                    suggestFromYear: suggest,
                    currentStage: current,
                    storedBand: band,
                    onChanged: (AgeValue v) => set(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    setUp(() => value = const AgeValue());

    testWidgets('eight years (nine back to two back), twelve months and six stages', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      for (int y = 2017; y <= 2024; y++) {
        expect(find.byKey(Key('year-$y')), findsOneWidget, reason: '$y');
      }
      expect(find.byKey(const Key('year-2016')), findsNothing);
      expect(find.byKey(const Key('year-2025')), findsNothing);
      for (int m = 1; m <= 12; m++) {
        expect(find.byKey(Key('month-$m')), findsOneWidget);
      }
      for (final SchoolStage s in SchoolStage.values) {
        expect(find.byKey(Key('stage-${s.wire}')), findsOneWidget);
      }
      // The earliest year is at the start of the row, which is the right in a right-to-left screen.
      expect(
        tester.getCenter(find.byKey(const Key('year-2017'))).dx,
        greaterThan(tester.getCenter(find.byKey(const Key('year-2018'))).dx),
      );
    });

    testWidgets('a year suggests the stage until the parent taps one; then the year no longer moves it', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      await _tap(tester, const Key('year-2021'));
      expect(value.stage, SchoolStage.gan5, reason: 'born 2021 in the school year of 2026');
      expect(find.textContaining(He.stageNames[SchoolStage.gan5.index].text), findsWidgets);
      expect(_selected(tester, const Key('stage-gan5')), isTrue);
      await _tap(tester, const Key('year-2022'));
      expect(value.stage, SchoolStage.gan4, reason: 'still following the year');
      await _tap(tester, const Key('stage-gan5'));
      await _tap(tester, const Key('year-2019'));
      expect(value.stage, SchoolStage.gan5, reason: 'the parent chose, so the year no longer decides');
      expect(value.stageChosen, isTrue);
    });

    testWidgets('on the age page the year never moves a confirmed stage; a note says what it suggests', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      value = const AgeValue(stage: SchoolStage.gan5, stageChosen: true);
      await pump(tester, suggest: false, current: SchoolStage.gan5);
      await _tap(tester, const Key('year-2019'));
      expect(value.stage, SchoolStage.gan5);
      expect(
        find.text(
          He.ageStageDiffers.fill(<String, String>{
            'suggested': He.stageNames[SchoolStage.grade2.index].text,
            'current': He.stageNames[SchoolStage.gan5.index].text,
          }),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a month with no year (or the reverse) says both are needed; "clear" empties both', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      expect(find.byKey(const Key('age-clear')), findsNothing);
      await _tap(tester, const Key('month-3'));
      expect(find.byKey(const Key('age-birth-both')), findsOneWidget);
      expect(value.birthHalf, isTrue);
      await _tap(tester, const Key('year-2021'));
      expect(find.byKey(const Key('age-birth-both')), findsNothing);
      expect(value.birthAt(now), const BirthMonth(2021, 3));
      await _tap(tester, const Key('age-clear'));
      expect(value.year, isNull);
      expect(value.month, isNull);
      expect(value.stage, SchoolStage.gan5, reason: 'the stage stays when the birth is cleared');
    });

    testWidgets('a stage of a lower band than the child has says the screens will look younger', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      value = const AgeValue(stage: SchoolStage.gan5, stageChosen: true);
      await pump(tester, suggest: false, current: SchoolStage.gan5, band: 1);
      expect(find.text(He.ageStageYounger.text), findsNothing);
      await _tap(tester, const Key('stage-gan4'));
      expect(find.text(He.ageStageYounger.text), findsOneWidget);
      await _tap(tester, const Key('stage-grade1'));
      expect(find.text(He.ageStageYounger.text), findsNothing);
    });

    testWidgets(
      'every chip says in words whether it is chosen (a check, never colour alone) and is 40 high at least',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(900, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pump(tester);
        await _tap(tester, const Key('year-2021'));
        expect(
          find.descendant(of: find.byKey(const Key('year-2021')), matching: find.byIcon(Icons.check_rounded)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: find.byKey(const Key('year-2020')), matching: find.byIcon(Icons.check_rounded)),
          findsNothing,
        );
        for (final Key k in const <Key>[Key('year-2021'), Key('month-1'), Key('stage-gan3')]) {
          expect(tester.getSize(find.byKey(k)).height, greaterThanOrEqualTo(40), reason: '$k');
        }
      },
    );
  });

  group('the child form', () {
    testWidgets('Save waits for a name and a school stage, and says why', (WidgetTester tester) async {
      final AppRig rig = await _rig();
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 2400));
      await tester.enterText(find.byType(TextField), 'דנה');
      await tester.pump();
      expect(_enabled(tester, const Key('form-save')), isFalse);
      expect(find.byKey(const Key('form-stage-needed')), findsOneWidget);
      await _tap(tester, const Key('stage-gan4'));
      expect(_enabled(tester, const Key('form-save')), isTrue);
      expect(find.byKey(const Key('form-stage-needed')), findsNothing);
    });

    testWidgets('the age chips of whole years are gone', (WidgetTester tester) async {
      final AppRig rig = await _rig();
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 2400));
      expect(
        find
            .byType(ChoiceChip)
            .evaluate()
            .where(
              (e) =>
                  (e.widget as ChoiceChip).label is Text &&
                  ((e.widget as ChoiceChip).label as Text).data == '7',
            ),
        isEmpty,
      );
      expect(find.text(He.setupAge.text), findsNothing);
    });

    testWidgets('saving keeps the stage, its band, the month and year and the school year', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig();
      await rig.db.removeProfile(langKid);
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 2400));
      await tester.enterText(find.byType(TextField), 'דנה');
      await _tap(tester, const Key('year-2021'));
      await _tap(tester, const Key('month-3'));
      await _tap(tester, const Key('form-save'));
      await tester.pumpAndSettle();
      final Profile p = (await rig.db.allProfiles()).single;
      expect(p.schoolStage, 'gan5');
      expect(p.ageBand, 1, reason: 'the band comes from the stage');
      expect(await rig.db.birthOf(p.id), const BirthMonth(2021, 3));
      expect(await rig.db.stageYearOf(p.id), 2026);
    });

    testWidgets('a younger stage gives Band A, and no birth is kept when none was given', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig();
      await rig.db.removeProfile(langKid);
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 2400));
      await tester.enterText(find.byType(TextField), 'דנה');
      await _tap(tester, const Key('stage-gan3'));
      await _tap(tester, const Key('form-save'));
      await tester.pumpAndSettle();
      final Profile p = (await rig.db.allProfiles()).single;
      expect(p.schoolStage, 'gan3');
      expect(p.ageBand, 0);
      expect(await rig.db.birthOf(p.id), isNull);
    });

    testWidgets('a month without a year blocks Save', (WidgetTester tester) async {
      final AppRig rig = await _rig();
      await rig.db.removeProfile(langKid);
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 2400));
      await tester.enterText(find.byType(TextField), 'דנה');
      await _tap(tester, const Key('stage-gan4'));
      await _tap(tester, const Key('month-5'));
      expect(_enabled(tester, const Key('form-save')), isFalse);
      expect(find.byKey(const Key('age-birth-both')), findsOneWidget);
    });
  });

  group('the age page', () {
    testWidgets(
      'it opens on what is stored and Save writes the stage, its band, the month and year and the school year',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(band: 0, stage: SchoolStage.gan4, birth: const BirthMonth(2022, 6));
        final Profile p = await langProfile(rig);
        await pumpParentScreen(
          tester,
          rig,
          AgePage(profile: p, onClose: () {}),
          size: const Size(820, 2400),
        );
        expect(_selected(tester, const Key('stage-gan4')), isTrue);
        expect(_selected(tester, const Key('year-2022')), isTrue);
        expect(_selected(tester, const Key('month-6')), isTrue);
        expect(find.text(He.ageChangeNote.text), findsOneWidget);
        await _tap(tester, const Key('stage-grade1'));
        await _tap(tester, const Key('year-2020'));
        await _tap(tester, const Key('age-save'));
        await tester.pumpAndSettle();
        final Profile after = await langProfile(rig);
        expect(after.schoolStage, 'grade1');
        expect(after.ageBand, 1);
        expect(await rig.db.birthOf(langKid), const BirthMonth(2020, 6));
        expect(await rig.db.stageYearOf(langKid), 2026);
      },
    );

    testWidgets('Cancel writes nothing', (WidgetTester tester) async {
      final AppRig rig = await _rig(band: 0, stage: SchoolStage.gan4, birth: const BirthMonth(2022, 6));
      final Profile p = await langProfile(rig);
      bool closed = false;
      await pumpParentScreen(
        tester,
        rig,
        AgePage(profile: p, onClose: () => closed = true),
        size: const Size(820, 2400),
      );
      await _tap(tester, const Key('stage-grade2'));
      await _tap(tester, const Key('age-cancel'));
      expect(closed, isTrue);
      expect((await langProfile(rig)).schoolStage, 'gan4');
      expect(await rig.db.birthOf(langKid), const BirthMonth(2022, 6));
    });

    testWidgets('the month and year can be cleared, and the stage stays', (WidgetTester tester) async {
      final AppRig rig = await _rig(band: 1, stage: SchoolStage.gan5, birth: const BirthMonth(2021, 3));
      final Profile p = await langProfile(rig);
      await pumpParentScreen(
        tester,
        rig,
        AgePage(profile: p, onClose: () {}),
        size: const Size(820, 2400),
      );
      await _tap(tester, const Key('age-clear'));
      await _tap(tester, const Key('age-save'));
      await tester.pumpAndSettle();
      expect(await rig.db.birthOf(langKid), isNull);
      expect((await langProfile(rig)).schoolStage, 'gan5');
    });

    testWidgets(
      'a child made before B-29 starts on the middle stage of its band, and a year suggests until a stage is tapped',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(band: 1);
        final Profile p = await langProfile(rig);
        await pumpParentScreen(
          tester,
          rig,
          AgePage(profile: p, onClose: () {}),
          size: const Size(820, 2400),
        );
        expect(_selected(tester, const Key('stage-gan5')), isTrue, reason: 'the middle of Band B');
        await _tap(tester, const Key('year-2020'));
        expect(_selected(tester, const Key('stage-grade1')), isTrue);
        expect(
          _enabled(tester, const Key('age-save')),
          isFalse,
          reason: 'a year with no month cannot be saved',
        );
        await _tap(tester, const Key('month-4'));
        await _tap(tester, const Key('age-save'));
        await tester.pumpAndSettle();
        expect((await langProfile(rig)).confirmedStage, SchoolStage.grade1);
      },
    );
  });

  group('the child\'s settings page', () {
    testWidgets('the age card says the stage and the month in words, and "change" opens the age page', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5, birth: const BirthMonth(2021, 3));
      await pumpParentScreen(
        tester,
        rig,
        ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
        size: const Size(820, 2400),
      );
      expect(find.text(He.stageNames[SchoolStage.gan5.index].text), findsOneWidget);
      expect(find.text('${He.months[2].text} 2021'), findsOneWidget);
      await tester.tap(find.byKey(const Key('age-change')));
      await tester.pumpAndSettle();
      expect(find.byType(AgePage), findsOneWidget);
    });

    testWidgets('with no month and year it says they were not entered', (WidgetTester tester) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await pumpParentScreen(
        tester,
        rig,
        ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
        size: const Size(820, 2400),
      );
      expect(find.text(He.ageBirthNone.text), findsOneWidget);
    });

    testWidgets(
      'the look: by age at first, a letter is saved at once as a letter in the family\'s looks, and "now" names its range',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(stage: SchoolStage.gan5, birth: const BirthMonth(2021, 3));
        await pumpParentScreen(
          tester,
          rig,
          ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
          size: const Size(820, 2400),
        );
        expect(_selected(tester, const Key('look-auto')), isTrue);
        expect(find.text(He.lookNow.fill(<String, String>{'range': He.langBandB.text})), findsOneWidget);
        await _tap(tester, const Key('look-2'));
        await tester.pumpAndSettle();
        expect(FamilyLooks.decode(await rig.db.setting(looksSettingKey)).bandOf(langKid), 2);
        expect(_selected(tester, const Key('look-2')), isTrue);
        expect(find.text(He.lookNow.fill(<String, String>{'range': He.langBandC.text})), findsOneWidget);
        await _tap(tester, const Key('look-auto'));
        await tester.pumpAndSettle();
        expect(FamilyLooks.decode(await rig.db.setting(looksSettingKey)).bandOf(langKid), isNull);
      },
    );

    testWidgets(
      'a look of a younger group never makes a child of 3 look older, and the status line says what is seen',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(band: 0, stage: SchoolStage.gan3, birth: const BirthMonth(2023, 9));
        await pumpParentScreen(
          tester,
          rig,
          ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
          size: const Size(820, 2400),
        );
        await _tap(tester, const Key('look-0'));
        await tester.pumpAndSettle();
        expect(find.text(He.lookNow.fill(<String, String>{'range': He.langBandA.text})), findsOneWidget);
      },
    );

    testWidgets(
      'the captions: by stage at first (hidden for gan 4), show and hide are kept on this device only',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(band: 0, stage: SchoolStage.gan4);
        await pumpParentScreen(
          tester,
          rig,
          ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
          size: const Size(820, 2400),
        );
        expect(_selected(tester, const Key('captions-auto')), isTrue);
        expect(
          find.text(
            He.captionsNowOff.fill(<String, String>{'stage': He.stageNames[SchoolStage.gan4.index].text}),
          ),
          findsOneWidget,
        );
        await _tap(tester, const Key('captions-on'));
        await tester.pumpAndSettle();
        expect(await rig.db.setting(readingKey(langKid)), 'on');
        expect(
          find.text(
            He.captionsNowOn.fill(<String, String>{'stage': He.stageNames[SchoolStage.gan4.index].text}),
          ),
          findsOneWidget,
        );
        // Not in the family's rules: nothing but a letter for the look travels.
        expect(await rig.db.setting(looksSettingKey), isNull);
        expect(find.text(He.captionsHelp.text), findsOneWidget);
      },
    );

    testWidgets(
      'one calm line suggests a tablet for a child of three on a phone, and only then (owner point O2)',
      (WidgetTester tester) async {
        final AppRig young = await _rig(band: 0, stage: SchoolStage.gan3, birth: const BirthMonth(2023, 9));
        await pumpParentScreen(
          tester,
          young,
          ChildSettingsScreen(profile: await langProfile(young), onClose: () {}),
          size: const Size(852, 393),
        );
        expect(find.byKey(const Key('look-tablet')), findsOneWidget);
      },
    );

    testWidgets('no such line on a tablet, nor for an older child', (WidgetTester tester) async {
      final AppRig young = await _rig(band: 0, stage: SchoolStage.gan3, birth: const BirthMonth(2023, 9));
      await pumpParentScreen(
        tester,
        young,
        ChildSettingsScreen(profile: await langProfile(young), onClose: () {}),
        size: const Size(820, 2400),
      );
      expect(find.byKey(const Key('look-tablet')), findsNothing);
    });

    testWidgets('no such line for a child of five on a phone', (WidgetTester tester) async {
      final AppRig older = await _rig(stage: SchoolStage.gan5, birth: const BirthMonth(2021, 3));
      await pumpParentScreen(
        tester,
        older,
        ChildSettingsScreen(profile: await langProfile(older), onClose: () {}),
        size: const Size(852, 393),
      );
      expect(find.byKey(const Key('look-tablet')), findsNothing);
    });
  });

  group('the parent area\'s cards', () {
    Future<void> area(WidgetTester tester, AppRig rig) =>
        pumpParentScreen(tester, rig, ParentArea(onClose: () {}), size: const Size(852, 2400));

    testWidgets('the child row\'s button is "settings" and opens the whole settings page', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.markStageConfirmed(langKid, DateTime(2026, 10, 26));
      await area(tester, rig);
      expect(find.text(He.areaChildSettings.text), findsOneWidget);
      await tester.tap(find.byKey(const Key('languages-$langKid')));
      await tester.pumpAndSettle();
      expect(find.byType(ChildSettingsScreen), findsOneWidget);
      expect(find.byKey(const Key('age-card')), findsOneWidget);
      expect(find.byKey(const Key('screens-card')), findsOneWidget);
    });

    testWidgets('31 August: no September card; 1 September: the card', (WidgetTester tester) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.putSetting(stageYearKey(langKid), '2025');
      rig.clock.now = DateTime(2026, 8, 31, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      expect(find.byKey(const Key('september-card-$langKid')), findsNothing);
    });

    testWidgets('1 September: the card asks, with the next stage and the current one', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.putSetting(stageYearKey(langKid), '2025');
      rig.clock.now = DateTime(2026, 9, 1, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      expect(find.byKey(const Key('september-card-$langKid')), findsOneWidget);
      expect(
        find.text(He.septQuestion.fill(<String, String>{'child': 'נועה', 'next': He.stageNamesTo[3].text})),
        findsOneWidget,
      );
      expect(find.text(He.septYes.fill(<String, String>{'next': He.stageNames[3].text})), findsOneWidget);
      expect(
        find.text(He.septKeep.fill(<String, String>{'current': He.stageNamesIn[2].text})),
        findsOneWidget,
      );
    });

    testWidgets('"yes" confirms the next stage and its band, and the card is gone', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.putSetting(stageYearKey(langKid), '2025');
      rig.clock.now = DateTime(2026, 9, 2, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      await tester.tap(find.byKey(const Key('sept-yes-$langKid')));
      await tester.pumpAndSettle();
      final Profile p = await langProfile(rig);
      expect(p.confirmedStage, SchoolStage.grade1);
      expect(p.ageBand, 1);
      expect(await rig.db.stageYearOf(langKid), 2026);
      expect(find.byKey(const Key('september-card-$langKid')), findsNothing);
    });

    testWidgets('"stay" keeps the stage and the card does not come back this year', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.putSetting(stageYearKey(langKid), '2025');
      rig.clock.now = DateTime(2026, 9, 2, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      await tester.tap(find.byKey(const Key('sept-keep-$langKid')));
      await tester.pumpAndSettle();
      expect((await langProfile(rig)).confirmedStage, SchoolStage.gan5);
      expect(await rig.db.stageYearOf(langKid), 2026);
      expect(find.byKey(const Key('september-card-$langKid')), findsNothing);
    });

    testWidgets('"another stage" opens the age page and changes nothing by itself', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.putSetting(stageYearKey(langKid), '2025');
      rig.clock.now = DateTime(2026, 9, 2, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      await tester.tap(find.byKey(const Key('sept-other-$langKid')));
      await tester.pumpAndSettle();
      expect(find.byType(AgePage), findsOneWidget);
      expect((await langProfile(rig)).confirmedStage, SchoolStage.gan5);
      expect(await rig.db.stageYearOf(langKid), 2025);
    });

    testWidgets('grade 3 never gets one', (WidgetTester tester) async {
      final AppRig rig = await _rig(band: 2, stage: SchoolStage.grade3);
      await rig.db.putSetting(stageYearKey(langKid), '2020');
      rig.clock.now = DateTime(2026, 9, 2, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      expect(find.byKey(const Key('september-card-$langKid')), findsNothing);
    });

    testWidgets('a child with no confirmed stage gets the "add the age" card, not the September one', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _rig();
      await area(tester, rig);
      expect(find.byKey(const Key('add-age-card-$langKid')), findsOneWidget);
      expect(find.byKey(const Key('september-card-$langKid')), findsNothing);
    });

    testWidgets(
      '"not now" hides it until the next 1 September, and "add" opens the age page with the middle of the band chosen',
      (WidgetTester tester) async {
        final AppRig rig = await _rig();
        await area(tester, rig);
        await tester.tap(find.byKey(const Key('add-age-yes-$langKid')));
        await tester.pumpAndSettle();
        expect(find.byType(AgePage), findsOneWidget);
        expect(_selected(tester, const Key('stage-gan5')), isTrue);
        await tester.tap(find.byKey(const Key('age-cancel')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add-age-later-$langKid')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('add-age-card-$langKid')), findsNothing);
        expect(await rig.db.ageCardHiddenYear(langKid), 2026);
      },
    );

    testWidgets('a stage that arrives from another phone counts as confirmed this school year', (
      WidgetTester tester,
    ) async {
      // The sync test of the pull covers the engine; here the keys the card reads are the ones the pull writes.
      final AppRig rig = await _rig(stage: SchoolStage.gan5);
      await rig.db.markStageConfirmed(langKid, DateTime(2026, 10, 26));
      rig.clock.now = DateTime(2026, 11, 2, 12).millisecondsSinceEpoch;
      await area(tester, rig);
      expect(find.byKey(const Key('september-card-$langKid')), findsNothing);
    });
  });

  group('deleting a child takes the age settings with it', () {
    test('the school year, the captions setting and the put-away card', () async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(id: langKid);
      await rig.db.markStageConfirmed(langKid, DateTime(2026, 10, 26));
      await rig.db.setCaptionSetting(langKid, CaptionSetting.on);
      await rig.db.hideAgeCard(langKid, DateTime(2026, 10, 26));
      await rig.db.deleteChildData(langKid);
      for (final String key in ageSettingKeys(langKid)) {
        expect(await rig.db.setting(key), isNull, reason: key);
      }
      await rig.db.close();
    });
  });
}
