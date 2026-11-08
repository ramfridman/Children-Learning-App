// B-29 steps 5 and 6: golden screenshots, in right to left with the real fonts. The activity by stage (one counting item authored with five
// options, so the cap shows: 3, 3, 4 and 5) on four boards, the home map by stage, the idle prompt, captions crossed with the stage, and the
// parent's pages. Compared with a tolerance of 3 percent of the pixels, as the others are.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_b29_stage_test.dart
// Run this file alone, and `git checkout` any golden of another file that a run rewrote.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/bundled_packs.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/age_page.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/parent/child_form.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

typedef _Look = ({String name, PresentationStage stage, SchoolStage school, BirthMonth birth});

// The rig's day is 2026-10-26. Each child is of an age in the middle of its look.
const List<_Look> _looks = <_Look>[
  (name: 'p1', stage: PresentationStage.p1, school: SchoolStage.gan3, birth: BirthMonth(2023, 8)),
  (name: 'p2', stage: PresentationStage.p2, school: SchoolStage.gan4, birth: BirthMonth(2022, 6)),
  (name: 'p3', stage: PresentationStage.p3, school: SchoolStage.gan5, birth: BirthMonth(2021, 3)),
  (name: 'p4', stage: PresentationStage.p4, school: SchoolStage.grade2, birth: BirthMonth(2019, 5)),
];

const List<(String, Size)> _boards = <(String, Size)>[
  ('phone', Size(852, 393)),
  ('phone_se', Size(667, 375)),
  ('tablet_landscape', Size(1180, 820)),
  ('tablet_portrait', Size(820, 1180)),
];

/// The starter pack with one counting item (apples) authored with five answer options, the right one and two tagged distractors among
/// them, so that the cap shows. The item is `b.mathb01.1` with its second group taken out and its options replaced.
Future<PackContent> _fiveOptionPack() async {
  final VerifiedPack pack = await verifyPack(
    File(bundledStarterAsset).readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  final Map<String, Object?> doc = pack.docs['activity.b.mathb01.1.json']! as Map<String, Object?>;
  final Map<String, Object?> scene = doc['scene']! as Map<String, Object?>..remove('group2');
  (scene['group']! as Map<String, Object?>)['count'] = 3;
  doc['answer'] = <String, Object?>{
    'type': 'choice',
    'options': <Map<String, Object?>>[
      for (int n = 1; n <= 5; n++)
        <String, Object?>{
          'id': 'o$n',
          'numeral': n,
          'label': '$n',
          if (n == 2 || n == 4) 'misconception': 'M-CNT-OFF',
        },
    ],
    'correct': 'o3',
    'shuffle': false,
    'unsureAllowed': true,
  };
  return PackContent.fromPack(pack);
}

Future<AppRig> _rig(
  WidgetTester tester,
  _Look look,
  Size size, {
  bool lessonContent = false,
  bool reduceMotion = true,
  String? captions,
}) async {
  final AppRig rig = AppRig(
    content: lessonContent ? await _fiveOptionPack() : null,
    butterfliesFirst: !lessonContent,
  );
  await rig.seedFinishedSetup(ageBand: look.school.band);
  await rig.db.confirmStage('p-1', look.school, DateTime(2026, 10, 26));
  await rig.db.setBirth('p-1', look.birth);
  if (captions != null) await rig.db.putSetting(readingKey('p-1'), captions);
  await rig.pump(tester, size: size, reduceMotion: reduceMotion);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  return rig;
}

Future<void> _openFiveOptions(WidgetTester tester, AppRig rig) async {
  final PackContent content = rig.content!;
  final Lesson lesson = Lesson.mission(
    id: 'five',
    itemIds: <String>['b.mathb01.1'],
    skillIds: <String>[content.activities['b.mathb01.1']!.skills.first.id],
    celebration: content.lessons.values.first.celebration,
  );
  unawaited(
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: lesson),
          ),
        ),
  );
  await _wait(tester);
}

Future<void> _wait(WidgetTester tester, [int ms = 2000]) async {
  for (int i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the activity by stage: a counting item with five options (the cap shows 3, 3, 4, 5)', () {
    for (final (String board, Size size) in _boards) {
      for (final _Look look in _looks) {
        testWidgets('${look.name} on $board', (WidgetTester tester) async {
          final AppRig rig = await _rig(tester, look, size, lessonContent: true);
          await _openFiveOptions(tester, rig);
          expect(
            find.byKey(const Key('answer-tile')),
            findsNWidgets(const <int>[3, 3, 4, 5][look.stage.index]),
          );
          await _shot(tester, 'stage_${look.name}_activity_$board');
        });
      }
    }
  });

  group('the home map by stage', () {
    for (final (String board, Size size) in _boards) {
      for (final _Look look in _looks) {
        testWidgets('${look.name} on $board', (WidgetTester tester) async {
          await _rig(tester, look, size);
          await tester.pumpAndSettle();
          await _shot(tester, 'stage_${look.name}_home_$board');
        });
      }
    }
  });

  group('the idle prompt (the hand drawn where it rests)', () {
    testWidgets(
      'P2 on the phone: the first prompt at 8 seconds, the hand in the stage (reduced motion: no ring)',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(tester, _looks[1], _boards[0].$2, lessonContent: true);
        await _openFiveOptions(tester, rig);
        await _wait(tester, 8500);
        expect(find.byKey(const Key('idle-hand')), findsOneWidget);
        await _shot(tester, 'stage_p2_idle_phone');
      },
    );

    testWidgets(
      'P4 on the phone: the second prompt at 40 seconds, the hand in the stage, none at the first (reduced motion: no ring)',
      (WidgetTester tester) async {
        final AppRig rig = await _rig(tester, _looks[3], _boards[0].$2, lessonContent: true);
        await _openFiveOptions(tester, rig);
        await _wait(tester, 20500);
        expect(find.byKey(const Key('idle-hand')), findsNothing, reason: 'P4: the first prompt has no hand');
        await _wait(tester, 20500);
        expect(find.byKey(const Key('idle-hand')), findsOneWidget);
        await _shot(tester, 'stage_p4_idle_phone');
      },
    );
  });

  group('captions crossed with the stage (the other extremes)', () {
    testWidgets('P1 with captions shown, phone: the floor size', (WidgetTester tester) async {
      final AppRig rig = await _rig(tester, _looks[0], _boards[0].$2, lessonContent: true, captions: 'on');
      await _openFiveOptions(tester, rig);
      await _shot(tester, 'stage_p1_captions_on_phone');
    });

    testWidgets('P4 with captions hidden, phone: the speaker bubble', (WidgetTester tester) async {
      final AppRig rig = await _rig(tester, _looks[3], _boards[0].$2, lessonContent: true, captions: 'off');
      await _openFiveOptions(tester, rig);
      await _shot(tester, 'stage_p4_captions_off_phone');
    });
  });

  group('the parent\'s pages', () {
    Future<AppRig> parentRig({SchoolStage? stage, BirthMonth? birth, int band = 1}) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(id: langKid, ageBand: band);
      if (stage != null) await rig.db.confirmStage(langKid, stage, DateTime(2026, 10, 26));
      if (birth != null) await rig.db.setBirth(langKid, birth);
      return rig;
    }

    testWidgets('the child form on a phone', (WidgetTester tester) async {
      final AppRig rig = await parentRig();
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(852, 1500));
      await tester.enterText(find.byType(TextField), 'נועה');
      await tester.pump();
      await tester.tap(find.byKey(const Key('year-2021')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('month-3')));
      await tester.pump();
      await tester.pumpAndSettle();
      await _shot(tester, 'b29_form_phone');
    });

    testWidgets('the child form on the small phone', (WidgetTester tester) async {
      final AppRig rig = await parentRig();
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(667, 1500));
      await tester.enterText(find.byType(TextField), 'נועה');
      await tester.pump();
      await tester.tap(find.byKey(const Key('year-2021')));
      await tester.pump();
      await tester.pumpAndSettle();
      await _shot(tester, 'b29_form_phone_se');
    });

    testWidgets('the child form on a tablet in portrait', (WidgetTester tester) async {
      final AppRig rig = await parentRig();
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(820, 1180));
      await tester.enterText(find.byType(TextField), 'נועה');
      await tester.pump();
      await tester.tap(find.byKey(const Key('year-2021')));
      await tester.pump();
      await tester.pumpAndSettle();
      await _shot(tester, 'b29_form_tablet_portrait');
    });

    testWidgets('the child form on the small phone at text size 1.3', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final AppRig rig = await parentRig();
      await pumpParentScreen(tester, rig, ChildFormScreen(onSaved: () {}), size: const Size(667, 1900));
      await tester.enterText(find.byType(TextField), 'נועה');
      await tester.pump();
      await tester.tap(find.byKey(const Key('year-2021')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no overflow and no clipping at 1.3');
      await _shot(tester, 'b29_form_phone_se_text13');
    });

    testWidgets('the child\'s settings page on a phone', (WidgetTester tester) async {
      final AppRig rig = await parentRig(stage: SchoolStage.gan5, birth: const BirthMonth(2021, 3));
      await pumpParentScreen(
        tester,
        rig,
        ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
        size: const Size(852, 1100),
      );
      await _shot(tester, 'b29_settings_phone');
    });

    testWidgets('the age page on a phone', (WidgetTester tester) async {
      final AppRig rig = await parentRig(stage: SchoolStage.gan5, birth: const BirthMonth(2021, 3));
      await pumpParentScreen(
        tester,
        rig,
        AgePage(profile: await langProfile(rig), onClose: () {}),
        size: const Size(852, 1100),
      );
      await _shot(tester, 'b29_age_page_phone');
    });

    testWidgets('the parent area with the September card and the "add the age" card', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await parentRig(stage: SchoolStage.gan5);
      await rig.db.addProfile(
        ProfilesCompanion.insert(
          id: 'child-bbbb-0002',
          name: 'איתי',
          avatar: 'avatar-noa',
          addressForm: 'm',
          ageBand: 0,
          createdAt: DateTime.utc(2026, 10, 26),
        ),
      );
      await rig.db.putSetting(stageYearKey(langKid), '2025');
      rig.clock.now = DateTime(2026, 9, 3, 12).millisecondsSinceEpoch;
      await pumpParentScreen(tester, rig, ParentArea(onClose: () {}), size: const Size(852, 900));
      await _shot(tester, 'b29_area_cards_phone');
    });
  });
}
