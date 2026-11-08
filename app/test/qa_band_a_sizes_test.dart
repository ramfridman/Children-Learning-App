// QA of Languages Band A (2026-11-07): the pictures to look at. One sample of every kind of activity of each course pack on the four boards
// (phone, phone SE, tablet landscape and portrait), with every clip PENDING (the app's own voice bank has none of the pack's lines, as in
// the shipped packs), after the fixed pauses; the hint levels of the listen-and-do samples; the Hebrew own-name item for several names.
//
//   NN_QA_VISUAL=1 flutter test --no-pub test/qa_band_a_sizes_test.dart
import 'dart:io';

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
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  Future<void> open(WidgetTester t, String course, PackContent content, Size size, Lesson lesson) async {
    final AppRig rig = AppRig(
      content: content,
      player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
    )..languagePacks = <String, PackContent>{course: content};
    await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
    await rig.db.putSetting(
      languagesSettingKey,
      const FamilyLanguages().withSwitches(langKid, course, const LanguageSwitches(on: true))!.encode(),
    );
    await rig.pump(t, size: size);
    await t.tap(find.text('נֹעָה').first);
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
    await waitFor(t, 4000);
  }

  final RegExp keyRe = RegExp(r'^(option-|tile-|item-|bin-|butterfly-|speaker-|obj-|card-|drum|word-)');
  for (final String course in Course.languages) {
    testWidgets(
      // A diagnostic that prints sizes and asserts none: it runs with NN_QA_VISUAL=1.
      skip: Platform.environment['NN_QA_VISUAL'] == null,
      '$course: the size of every touch target of every kind of activity, on four boards',
      (WidgetTester t) async {
        final PackKey key = await newTestKey();
        final VerifiedPack pack = await verifyPack(
          (await buildPack(languageSource(course, _languages), key)).bytes,
          publicKey: key.publicKey,
        );
        final PackContent content = PackContent.fromPack(pack);
        final Map<String, String> samples = <String, String>{};
        for (final MapEntry<String, Object?> e in pack.docs.entries) {
          if (!e.key.startsWith('activity.')) continue;
          final Map<String, Object?> a = e.value! as Map<String, Object?>;
          // A teach or hearing screen is never a lesson item (SEC-BA-2): a lesson shows it from its `teach` entries, so a lesson of one
          // screen would be refused. Their look is the golden of the route screens.
          if (_isScreen(a)) continue;
          samples.putIfAbsent(_kind(a), () => a['id']! as String);
        }
        for (final MapEntry<String, Size> b in boards.entries) {
          for (final MapEntry<String, String> s in samples.entries) {
            final Activity a = content.activities[s.value]!;
            final Lesson lesson = Lesson.mission(
              id: 'shot',
              itemIds: <String>[a.id],
              skillIds: <String>[a.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            );
            await open(t, course, content, b.value, lesson);
            final List<String> found = <String>[];
            t.allWidgets
                .where(
                  (Widget w) =>
                      w.key is ValueKey<String> && keyRe.hasMatch((w.key! as ValueKey<String>).value),
                )
                .forEach((Widget w) {
                  final Finder f = find.byWidget(w);
                  if (f.evaluate().isEmpty) return;
                  final Size sz = t.getSize(f.first);
                  found.add('${(w.key! as ValueKey<String>).value}=${sz.width.round()}x${sz.height.round()}');
                });
            // ignore: avoid_print
            print('QA-SIZE $course ${b.key} ${s.key} ${a.id}: ${found.join(' ')}');
            await t.pumpWidget(const SizedBox());
          }
        }
      },
    );
  }
}
