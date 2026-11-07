// QA of Languages Band A (2026-11-07): the pictures to look at. One sample of every kind of activity of each course pack on the four boards
// (phone, phone SE, tablet landscape and portrait), with every clip PENDING (the app's own voice bank has none of the pack's lines, as in
// the shipped packs), after the fixed pauses; the hint levels of the listen-and-do samples; the Hebrew own-name item for several names.
//
//   NN_SHOTS=<folder> flutter test --no-pub test/qa_band_a_shots_test.dart
//
// The playthrough of every kind on four boards takes about half an hour, so it runs only when `NN_SHOTS` names a folder (it then writes a
// picture of each) or `NN_QA_VISUAL` is set; the suite runs the quick guard of the samples (no teach or hearing screen is one).
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

/// A teach screen or a hearing screen: a `say_it` step flagged by its answer.
bool _isScreen(Map<String, Object?> a) {
  final Object? answer = a['answer'];
  return answer is Map<String, Object?> && (answer['teach'] == true || answer['hear'] == true);
}

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
  final String special = <String>[
    if (answer['type'] == 'name') 'name-${answer['unit']}',
    if (answer['teach'] == true) 'teach',
    if (answer['hear'] == true) 'hear',
    if (a['font'] == 'display') 'display',
    if ((a['say'] as Map<String, Object?>?)?['pictureFirst'] != null) 'picfirst',
    if (a['purpose'] == 'probe') 'probe',
  ].join(' ');
  final String extra = t == 'tap_answer'
      ? (answer['all'] == true
            ? 'all'
            : sound
            ? 'sound'
            : scene['group'] != null
            ? 'stage'
            : answer['pole'] != null
            ? 'pole'
            : options.length == 2
            ? 'two'
            : 'plain')
      : t == 'trace'
      ? 'path'
      : '';
  return '$t $mode $extra $special'.trim();
}

void main() {
  final String? shots = Platform.environment['NN_SHOTS'];
  final String? skipped = shots != null || Platform.environment['NN_QA_VISUAL'] != null
      ? null
      : 'a half-hour playthrough: set NN_SHOTS=<folder> (it writes the pictures) or NN_QA_VISUAL=1';
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    if (shots != null) {
      Directory(shots).createSync(recursive: true);
      goldenFileComparator = _Shots(Directory(shots));
    }
  });

  Future<void> open(
    WidgetTester t,
    String course,
    PackContent content,
    Size size,
    Lesson lesson, {
    String name = 'נֹעָה',
    int wait = 6500,
  }) async {
    final AppRig rig = AppRig(
      content: content,
      player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
    )..languagePacks = <String, PackContent>{course: content};
    await rig.seedFinishedSetup(name: name, id: langKid);
    await rig.db.putSetting(
      languagesSettingKey,
      const FamilyLanguages().withSwitches(langKid, course, const LanguageSwitches(on: true))!.encode(),
    );
    await rig.pump(t, size: size);
    await t.tap(find.text(name.isEmpty ? 'a' : name).first);
    await t.pumpAndSettle();
    t
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) =>
                LessonScreen(profileId: langKid, course: course, lessonId: lesson.id, mission: lesson),
          ),
        );
    await t.pump(const Duration(milliseconds: 600));
    await waitFor(t, wait);
  }

  for (final String course in Course.languages) {
    test(
      '$course: no sample is a teach or a hearing screen (a lesson of one screen is refused: SEC-BA-2)',
      () async {
        final PackKey key = await newTestKey();
        final VerifiedPack pack = await verifyPack(
          (await buildPack(languageSource(course, _languages), key)).bytes,
          publicKey: key.publicKey,
        );
        final Set<String> samples = <String>{};
        int screens = 0;
        for (final MapEntry<String, Object?> e in pack.docs.entries) {
          if (!e.key.startsWith('activity.')) continue;
          final Map<String, Object?> a = e.value! as Map<String, Object?>;
          if (_isScreen(a)) {
            screens++;
            continue;
          }
          samples.add(_kind(a));
        }
        expect(samples, isNotEmpty);
        expect(samples.any((String k) => k.contains('teach') || k.contains('hear')), isFalse);
        if (course == 'rus') {
          expect(screens, greaterThan(0), reason: 'the Russian pack has the screens the guard keeps out');
        }
      },
    );

    group(course, skip: skipped, () {
      late PackContent content;
      final Map<String, String> samples = <String, String>{};
      setUpAll(() async {
        final PackKey key = await newTestKey();
        final VerifiedPack pack = await verifyPack(
          (await buildPack(languageSource(course, _languages), key)).bytes,
          publicKey: key.publicKey,
        );
        content = PackContent.fromPack(pack);
        for (final MapEntry<String, Object?> e in pack.docs.entries) {
          if (!e.key.startsWith('activity.')) continue;
          final Map<String, Object?> a = e.value! as Map<String, Object?>;
          // A teach or hearing screen is never a lesson item (SEC-BA-2): a lesson shows it from its `teach` entries, so a lesson of one
          // screen would be refused. Their look is the golden of the route screens.
          if (_isScreen(a)) continue;
          samples.putIfAbsent(_kind(a), () => a['id']! as String);
        }
      });

      for (final MapEntry<String, Size> b in boards.entries) {
        testWidgets('${b.key}: every kind, clips pending', (WidgetTester t) async {
          final List<String> failed = <String>[];
          for (final MapEntry<String, String> s in samples.entries) {
            final Activity a = content.activities[s.value]!;
            final Lesson lesson = Lesson.mission(
              id: 'shot',
              itemIds: <String>[a.id],
              skillIds: <String>[a.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            );
            await open(t, course, content, b.value, lesson);
            final Object? ex = t.takeException();
            if (ex != null) failed.add('${s.key} ${a.id}: $ex');
            if (shots != null) {
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile('${course}_${s.key.replaceAll(' ', '_')}_${b.key}.png'),
              );
            }
            await t.pumpWidget(const SizedBox());
          }
          expect(failed, isEmpty, reason: failed.join('\n'));
        });
      }

      testWidgets('phone: hint levels of every listen_do mode and the tap kinds', (WidgetTester t) async {
        final List<String> failed = <String>[];
        final Map<String, String> pick = <String, String>{
          for (final MapEntry<String, String> s in samples.entries)
            if (s.key.startsWith('listen_do') ||
                s.key.startsWith('tap_answer  plain') ||
                s.key.startsWith('story'))
              s.key: s.value,
        };
        for (final MapEntry<String, String> s in pick.entries) {
          final Activity a = content.activities[s.value]!;
          if (a.hints.isEmpty) continue;
          final Lesson lesson = Lesson.mission(
            id: 'shot',
            itemIds: <String>[a.id],
            skillIds: <String>[a.skillId],
            celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
          );
          await open(t, course, content, boards['phone']!, lesson, wait: 3000);
          for (int level = 1; level <= a.hints.length; level++) {
            if (find.byKey(const Key('lesson-hint')).evaluate().isEmpty) break;
            await t.tap(find.byKey(const Key('lesson-hint')));
            await waitFor(t, 3500);
            final Object? ex = t.takeException();
            if (ex != null) failed.add('${s.key} ${a.id} hint $level: $ex');
            if (shots != null) {
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile('hint_${course}_${s.key.replaceAll(' ', '_')}_L$level.png'),
              );
            }
          }
          await t.pumpWidget(const SizedBox());
        }
        expect(failed, isEmpty, reason: failed.join('\n'));
      });
    });
  }

  testWidgets(
    skip: skipped != null,
    'heb: the own-name item for a pointed, a Latin, no, a long and an in-list name',
    (WidgetTester t) async {
      final PackKey key = await newTestKey();
      final PackContent content = PackContent.fromPack(
        await verifyPack(
          (await buildPack(languageSource('heb', _languages), key)).bytes,
          publicKey: key.publicKey,
        ),
      );
      final List<Activity> items = <Activity>[
        for (final Activity a in content.activities.values)
          if (a.skillId == 'HEB-A-11') a,
      ]..sort((Activity x, Activity y) => x.id.compareTo(y.id));
      final Map<String, String> names = <String, String>{
        'pointed': 'נֹעָה',
        'latin': 'Noa',
        'long': 'אֲבִיגָיִל־יוֹנָה',
        'inlist': 'דָּנִי',
      };
      final List<String> failed = <String>[];
      for (final MapEntry<String, String> n in names.entries) {
        for (final Activity a in items) {
          final Lesson lesson = Lesson.mission(
            id: 'shot',
            itemIds: <String>[a.id],
            skillIds: <String>[a.skillId],
            celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
          );
          await open(t, 'heb', content, boards['phone']!, lesson, name: n.value, wait: 3000);
          final Object? ex = t.takeException();
          if (ex != null) failed.add('${n.key} ${a.id}: $ex');
          if (shots != null) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('name_${n.key}_${a.id.split('.').last}_phone.png'),
            );
          }
          await t.pumpWidget(const SizedBox());
        }
      }
      expect(failed, isEmpty, reason: failed.join('\n'));
    },
  );
}
