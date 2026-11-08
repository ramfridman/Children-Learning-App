// QA of Languages Band A (2026-11-07): the real packs through the real app on the four boards with every clip PENDING (the app's voice
// bank holds none of the pack's lines): the door, the course home, the placement visit, the first lesson of the course to its celebration and
// back to the home. Pictures of the home, the first activity, the celebration and the home after it are written when NN_SHOTS names a folder.
//
//   NN_SHOTS=<folder> flutter test --no-pub test/qa_band_a_flow_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import '../tool/pack_builder_lib.dart';
import 'language_pilot_test.dart' show passTeachScreens, playPlacement;
import 'support/app_harness.dart';
import 'support/course_flow.dart';
import 'support/course_history.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_golden.dart' show boards;
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const String _languages = '../content/languages';

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

const Map<String, ({int items, int teach})> _first = <String, ({int items, int teach})>{
  'eng': (items: 5, teach: 0),
  'heb': (items: 4, teach: 0),
  'rus': (items: 3, teach: 4),
};

void main() {
  final String? shots = Platform.environment['NN_SHOTS'];
  late Map<String, PackContent> packs;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    if (shots != null) {
      Directory(shots).createSync(recursive: true);
      goldenFileComparator = _Shots(Directory(shots));
    }
    final PackKey key = await newTestKey();
    packs = <String, PackContent>{
      for (final String c in Course.languages)
        c: PackContent.fromPack(
          await verifyPack(
            (await buildPack(languageSource(c, _languages), key)).bytes,
            publicKey: key.publicKey,
          ),
        ),
    };
  });

  for (final String course in Course.languages) {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '$course on the ${b.key} board, clips pending: home, placement, lesson, celebration, home',
        (WidgetTester tester) async {
          final AppRig rig = AppRig(player: FakePlayer()..endsAfter = const Duration(milliseconds: 150))
            ..languagePacks = packs;
          await rig.seedFinishedSetup(id: courseKid);
          await rig.db.putSetting(
            languagesSettingKey,
            const FamilyLanguages()
                .withSwitches(courseKid, course, const LanguageSwitches(on: true))!
                .encode(),
          );
          await rig.pump(tester, size: b.value);
          await tester.tap(find.text('נועה'));
          await tester.pumpAndSettle();
          await openCourse(tester, course);
          expect(find.byType(CourseHomeScreen), findsOneWidget);
          if (shots != null) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('flow_${course}_${b.key}_1home.png'),
            );
          }
          await playPlacement(tester);
          if (shots != null) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('flow_${course}_${b.key}_2home_after_placement.png'),
            );
          }
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          expect(find.byType(LessonScreen), findsOneWidget);
          final ({int items, int teach}) f = _first[course]!;
          if (shots != null && f.teach > 0) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('flow_${course}_${b.key}_3teach.png'),
            );
          }
          await passTeachScreens(tester, f.teach);
          for (int i = 0; i < f.items; i++) {
            expect(find.byKey(const Key('option-o1')), findsOneWidget, reason: 'item ${i + 1} is on screen');
            if (i == 0 && shots != null) {
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile('flow_${course}_${b.key}_4first.png'),
              );
            }
            await answer(tester);
          }
          expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
          if (shots != null) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('flow_${course}_${b.key}_5celebration.png'),
            );
          }
          await tester.tap(find.byKey(const Key('lesson-done')));
          await tester.pumpAndSettle();
          expect(find.byType(CourseHomeScreen), findsOneWidget, reason: 'back on the course home');
          if (shots != null) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('flow_${course}_${b.key}_6home_after.png'),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
