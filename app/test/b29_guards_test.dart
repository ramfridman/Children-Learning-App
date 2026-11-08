// B-29 step 9, the guards that are not about a birthday and the lessons (those are in birthday_changes_nothing_test.dart): a stage or look change
// shows only at the next session; no age reaches the tutor; a language start and the course path never read age; Today's Adventure reads
// only the school stage; the picker always draws the youngest sizes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/tutor/tutor.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const String kidId = 'child-guard-0001';

Future<void> _wait(WidgetTester tester, [int ms = 1500]) async {
  for (int i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The side of the first answer tile on screen.
double _tile(WidgetTester tester) => tester.getSize(find.byKey(const Key('answer-tile')).first).width;

Future<void> _openLesson(WidgetTester tester) async {
  await openActivities(tester, <String>['pick.numeral.1']);
  await _wait(tester);
}

Future<void> _closeLesson(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await _wait(tester, 800);
}

void main() {
  setUpAll(loadAppFonts);

  group('a stage or look change applies at the next session, never mid-activity', () {
    testWidgets('the tiles keep the look the visit began with, and the next visit has the new one', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig(butterfliesFirst: true);
      await rig.seedFinishedSetup(ageBand: 1);
      await rig.db.confirmStage('p-1', SchoolStage.gan5, DateTime(2026, 10, 26));
      await rig.db.setBirth('p-1', const BirthMonth(2021, 3)); // 5;7 on the rig's day: P3
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();

      await _openLesson(tester);
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(_tile(tester), 88, reason: 'P3: a tile of 88 points on a phone');

      // A parent, mid-activity, confirms grade 2 and gives another month.
      await rig.db.confirmStage('p-1', SchoolStage.grade2, DateTime(2026, 10, 26));
      await rig.db.setBirth('p-1', const BirthMonth(2019, 5));
      await _wait(tester, 3000);
      expect(_tile(tester), 88, reason: 'nothing changes under a child mid-activity');

      await _closeLesson(tester);
      await _openLesson(tester);
      expect(_tile(tester), 80, reason: 'the next visit: grade 2, 7;5 months old: P4, a tile of 80');
    });
  });

  group('the AI tutor is told the band and nothing about age', () {
    test('a request holds ids, numbers and enums: no age, no stage, no birth, no look', () {
      const TutorAsk ask = TutorAsk(
        childRef: 'child-guard-0001',
        sessionRef: 's',
        packId: 'starter',
        packVersion: '0.10.0',
        itemId: 'a',
        characterId: 'hero-son',
        band: 'B',
        addressForm: 'f',
        hintLevel: 0,
        mistakes: <String>['default'],
      );
      expect(ask.toJson().keys.toSet(), <String>{
        'child_ref',
        'session_ref',
        'pack_id',
        'pack_version',
        'item_id',
        'character_id',
        'band',
        'address_form',
        'hint_level',
        'mode',
        'mistakes',
        'attempts',
      });
      expect(
        ask.toJson().keys.join(' '),
        isNot(matches(RegExp('birth|born|age|stage|look|month', caseSensitive: false))),
      );
    });

    test('the tutor files cannot name an age, a stage or a look (source rule)', () {
      final RegExp names = RegExp(
        r'SchoolStage|PresentationStage|ChildAge|childAge|BirthMonth|schoolStage|looksSettingKey|FamilyLooks|ageInMonths',
      );
      for (final FileSystemEntity f in Directory('lib/tutor').listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          expect(names.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
        }
      }
    });
  });

  group('a language start and the course path never read age', () {
    test('the placement of a language and its staircase cannot name an age (source rule)', () {
      final RegExp age = RegExp(
        r'age\.dart|ChildAge|childAge|BirthMonth|ageInMonths|PresentationStage|SchoolStage|birthOf|\.months\b|schoolStage',
      );
      for (final String path in <String>[
        'lib/world/language_placement.dart',
        'lib/engine/staircase.dart',
        'lib/world/course_path.dart',
        'lib/engine/course.dart',
        'lib/engine/course_rules.dart',
        'lib/engine/check_visit.dart',
      ]) {
        expect(age.hasMatch(File(path).readAsStringSync()), isFalse, reason: path);
      }
    });
  });

  group('Today\'s Adventure reads only the school stage', () {
    test('the row is the stage\'s band\'s, for each of the six stages', () {
      for (final SchoolStage s in SchoolStage.values) {
        final AdventureParams row = paramsForStage(s);
        final AdventureParams byBand = paramsFor(band: s.band);
        expect(row.newAfterRevisit, byBand.newAfterRevisit, reason: s.wire);
        expect(row.stayInLand, byBand.stayInLand, reason: s.wire);
      }
    });

    test('the rule file reads no age, no look and no birth (source rule)', () {
      final String src = File('lib/world/todays_adventure.dart').readAsStringSync();
      expect(
        RegExp(r'ChildAge|childAge|BirthMonth|ageInMonths|PresentationStage|birthOf|\.months\b|FamilyLooks')
            .hasMatch(src),
        isFalse,
      );
      expect(src, contains("import '../engine/age.dart' show SchoolStage;"));
    });
  });

  group('the picker is the youngest look whatever the children\'s stages', () {
    test(
      'it reads no stage at all: its sizes are the board\'s own, the same for every child (source rule)',
      () {
        final String src = File('lib/child/profile_picker.dart').readAsStringSync();
        expect(RegExp(r'StageScope|StageSpec|PresentationStage|lookFor|LookNow').hasMatch(src), isFalse);
      },
    );
  });
}
