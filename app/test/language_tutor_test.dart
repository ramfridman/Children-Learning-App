// The AI tutor is off in language lessons (docs/languages/frame.md section 1.6): the app never asks for a tutor line for an item
// of a language course, whatever its file says, and a gateway that refuses one is not a fault. Hints are the authored ladders.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/tutor/tutor.dart';

import 'support/fake_tutor.dart';
import 'support/fakes.dart';
import 'support/sample_pack.dart';

/// A fixture pack in which every activity says the tutor may speak, which a language pack's validator would refuse; this
/// is the worst case the app has to hold on its own.
PackContent _tutorFriendly(SamplePack p) {
  for (final MapEntry<String, Object?> d in p.docs.entries) {
    if (d.key.startsWith('activity.')) {
      ((d.value! as Map<String, Object?>)['tutor']! as Map<String, Object?>)['llmAllowed'] = true;
    }
  }
  return PackContent.fromPack(p.verified());
}

void main() {
  /// A lesson with the tutor attached, and the wrong answers a child could give to its first activity.
  Future<(LessonController, FakeTutorClient)> play(PackContent content) async {
    final FakeTutorClient client = FakeTutorClient();
    final LessonController c = LessonController(
      content: content,
      lesson: content.lessons['butterflies']!,
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
      tutor: TutorSession(client: client),
      tutorContext: TutorContext(
        packId: content.packId,
        packVersion: content.packVersion,
        characterId: 'nitzi',
        band: 'A',
        addressForm: 'n',
        childRef: 'kid-0000-aaaa',
        sessionRef: 'ses-0000-aaaa',
      ),
    );
    // The first item that has a wrong answer to give (a choice): wrong, then wrong again, then once more.
    final String wrong = (c.current as CountTapActivity).options
        .firstWhere((ChoiceOption o) => o.id != 'o2')
        .id;
    for (int i = 0; i < 3; i++) {
      await c.chooseOption(wrong);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return (c, client);
  }

  /// The count activity is the second item of the fixture lesson; the lesson opens on it for this test.
  PackContent countFirst(SamplePack p) {
    final Map<String, Object?> lesson = p.doc('lesson.butterflies.json');
    lesson['items'] = <Object?>['count.butterflies.3', 'pick.red.flower', 'give.three.jar'];
    return _tutorFriendly(p);
  }

  test('control: in the lands an activity that allows the tutor does ask for its line', () async {
    final (LessonController _, FakeTutorClient client) = await play(countFirst(SamplePack()));
    expect(client.asked, isNotEmpty, reason: 'the test can see a tutor question when there is one');
  });

  for (final String course in <String>['eng', 'heb', 'rus']) {
    test(
      '$course: no line is asked for, ahead of time or after a mistake, and the authored help is used',
      () async {
        final PackContent content = countFirst(SamplePack.language(course));
        expect(content.activities.values.every((Activity a) => !a.llmAllowed), isTrue);
        final (LessonController c, FakeTutorClient client) = await play(content);
        expect(client.asked, isEmpty, reason: 'not a question, not a prefetch');
        expect(c.tutorThinking, isFalse);
        expect(c.hintLevel, greaterThan(0), reason: 'the authored ladder was used');
      },
    );
  }

  test(
    'a gateway that refuses a language item is not a fault, and the lesson goes on with its own lines',
    () async {
      final FakeTutorClient client = FakeTutorClient()..rule = 'course_not_allowed';
      final TutorSession session = TutorSession(client: client);
      final List<TutorResult> r = await client.ask(
        const TutorAsk(
          childRef: 'kid-0000-aaaa',
          sessionRef: 'ses-0000-aaaa',
          packId: 'lang-eng',
          packVersion: '1.0.0',
          itemId: 'x',
          characterId: 'nitzi',
          band: 'A',
          addressForm: 'n',
          hintLevel: 0,
          mistakes: <String>['default'],
        ),
      );
      expect(r.single.rule, 'course_not_allowed');
      await session.prefetch(
        const TutorAsk(
          childRef: 'kid-0000-aaaa',
          sessionRef: 'ses-0000-aaaa',
          packId: 'lang-eng',
          packVersion: '1.0.0',
          itemId: 'x',
          characterId: 'nitzi',
          band: 'A',
          addressForm: 'n',
          hintLevel: 0,
          mistakes: <String>['default'],
          prefetch: true,
        ),
      );
      expect(session.failures, 0, reason: 'a refusal for a course is no failure of the service');
      expect(session.available, isFalse, reason: 'and the rest of this lesson does not ask again');
    },
  );
}
