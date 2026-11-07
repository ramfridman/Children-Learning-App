// Every kind of activity the real Band A packs hold, in each course, opened on the lesson screen with the real pack: one sample of each
// template and mode (a tap with a stage picture, sound buttons, a tap-all, a command by buttons, hotspots, cards, a drag or a place, a
// puppet's bubble and its personal turn, a say step, a chant, the drum, a story heard and one that asks, a count, pairs, a sort, a story
// line, the pre-writing path). Each must open without an error and show its stage; the answers are played by the playthrough tests.
//
// To look at them: `NN_SHOTS=<folder> flutter test test/language_band_a_templates_test.dart` writes a picture of each sample on the phone
// and the tablet to that folder (the same render as the goldens; nothing is compared).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_golden.dart' show boards, waitFor;
import 'support/language_screens.dart' show langKid;
import 'support/language_voice.dart';
import 'support/voice_fixtures.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

/// Writes the picture of a screen to a folder instead of comparing it.
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

/// What kind of sample an activity is: its template and the mode or the face that makes it look different.
String _kind(Map<String, Object?> a) {
  final Map<String, Object?> answer = (a['answer'] as Map<String, Object?>?) ?? const <String, Object?>{};
  final Map<String, Object?> scene = (a['scene'] as Map<String, Object?>?) ?? const <String, Object?>{};
  final String t = a['template']! as String;
  final List<Object?> options = (answer['options'] as List<Object?>?) ?? const <Object?>[];
  final bool sound =
      options.isNotEmpty &&
      options.every(
        (Object? o) => (o! as Map<String, Object?>).keys.every(
          (String k) => k != 'sprite' && k != 'text' && k != 'numeral',
        ),
      );
  final String mode = answer['mode'] is String ? answer['mode']! as String : '';
  final String extra = t == 'tap_answer'
      ? (answer['all'] == true
            ? 'all'
            : sound
            ? 'sound'
            : scene['group'] != null
            ? 'stage'
            : answer['pole'] != null
            ? 'pole'
            : 'plain')
      : t == 'trace'
      ? 'path'
      : '';
  return '$t $mode $extra'.trim();
}

Set<String> _refs(Object? n) {
  final Set<String> out = <String>{};
  void scan(Object? x) {
    if (x is String && x.startsWith('vo:')) out.add(x);
    if (x is Map<String, Object?>) x.values.forEach(scan);
    if (x is List<Object?>) x.forEach(scan);
  }

  scan(n);
  return out;
}

void main() {
  final String? shots = Platform.environment['NN_SHOTS'];

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    if (shots != null) {
      Directory(shots).createSync(recursive: true);
      goldenFileComparator = _Shots(Directory(shots));
    }
  });

  for (final String course in Course.languages) {
    group(course, () {
      late VerifiedPack pack;
      late PackContent content;
      final Map<String, String> samples = <String, String>{};

      setUpAll(() async {
        final PackKey key = await newTestKey();
        pack = await verifyPack(
          (await buildPack(languageSource(course, _languages), key)).bytes,
          publicKey: key.publicKey,
        );
        content = PackContent.fromPack(pack);
        for (final MapEntry<String, Object?> e in pack.docs.entries) {
          if (!e.key.startsWith('activity.')) continue;
          final Map<String, Object?> a = e.value! as Map<String, Object?>;
          samples.putIfAbsent(_kind(a), () => a['id']! as String);
        }
      });

      for (final MapEntry<String, Size> b in boards.entries.where(
        (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'tabletLandscape',
      )) {
        testWidgets('one sample of every kind of activity opens on the ${b.key} board', (
          WidgetTester t,
        ) async {
          expect(samples.length, greaterThan(8), reason: 'the pack has several kinds of activity');
          for (final MapEntry<String, String> s in samples.entries) {
            final Activity a = content.activities[s.value]!;
            final AppRig rig = AppRig(
              content: content,
              characters: await languageVoiceSource(_refs(pack.docs)),
              player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
            )..languagePacks = <String, PackContent>{course: content};
            await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
            await rig.db.putSetting(
              languagesSettingKey,
              const FamilyLanguages()
                  .withSwitches(langKid, course, const LanguageSwitches(on: true))!
                  .encode(),
            );
            await rig.pump(t, size: b.value);
            await t.tap(find.text('נֹעָה'));
            await t.pumpAndSettle();
            t
                .state<NavigatorState>(find.byType(Navigator).first)
                .push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext c) => LessonScreen(
                      profileId: langKid,
                      course: course,
                      mission: Lesson.mission(
                        id: 'shot',
                        itemIds: <String>[a.id],
                        skillIds: <String>[a.skillId],
                        celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
                      ),
                    ),
                  ),
                );
            await t.pump(const Duration(milliseconds: 600));
            await waitFor(t, 2200);
            expect(find.byType(LessonScreen), findsOneWidget, reason: s.key);
            expect(t.takeException(), isNull, reason: '${s.key}: ${a.id}');
            if (shots != null) {
              final String name = s.key.replaceAll(' ', '_');
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile('${course}_${name}_${b.key}.png'),
              );
            }
            // leave the screen and the app, so that the next sample starts clean
            await t.pumpWidget(const SizedBox());
          }
        });
      }
    });
  }
}
