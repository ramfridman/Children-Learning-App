// Hebrew blend items (HEB-A-09, "bu ... ba": a syllable string, the child picks the picture that is the word): after a right answer the praise ends
// on the right picture's whole-word clip, never on the split syllables (docs/languages/frame.md section 2.3, ruled 2026-11-15). The pack is built from
// the course's source with a test key.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

void main() {
  late PackContent heb;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    final Uint8List bytes = (await buildPack(languageSource('heb', _languages), key)).bytes;
    heb = PackContent.fromPack(await verifyPack(bytes, publicKey: key.publicKey));
  });

  /// The blend choices of the course: a tap whose prompt is a syllable string.
  Iterable<Activity> blends() => heb.activities.values.where(
    (Activity a) =>
        a is ChoiceActivity &&
        a.id.startsWith('heb.a09.') &&
        a.promptLine.target?.contains('heb_a_u_') == true,
  );

  ChoiceOption rightOf(Activity a) {
    final ChoiceActivity choice = a as ChoiceActivity;
    return choice.options.firstWhere((ChoiceOption o) => o.id == choice.correctId);
  }

  test('the course has blend items to check', () {
    expect(blends().length, greaterThanOrEqualTo(9));
  });

  test('every blend item praises on the whole word of the right picture, not on the syllables', () {
    for (final Activity a in blends()) {
      final String? praised = a.feedback.correct.target;
      expect(praised, rightOf(a).clip, reason: '${a.id}: the praise ends on the picture\'s own whole word');
      expect(praised, isNot(a.promptLine.target), reason: '${a.id}: not the split syllables again');
      expect(praised, contains('heb_a_w_'), reason: '${a.id}: a whole-word clip');
    }
  });

  test(
    'a right answer plays the praise and then the whole word of the picture (bu ... ba, then buba)',
    () async {
      final LessonController c = LessonController(
        content: heb,
        lesson: heb.lessons['heb.blend-1']!,
        profileId: 'kid',
        record: (AttemptRecord r) async {},
        route: 'new',
        introVisit: true,
      );
      while (c.current.id != 'heb.a09.01') {
        c.next();
      }
      expect(c.voiceTarget, 'vo:heb.heb_a_u_buba', reason: 'the prompt says the syllables');
      await c.chooseOption((c.current as ChoiceActivity).correctId);
      expect(c.voice, 'vo:heb.ok_1', reason: 'the praise line');
      expect(c.voiceTarget, 'vo:heb.heb_a_w_buba', reason: 'ends on the whole word');
      c.dispose();
    },
  );
}
