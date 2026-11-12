// First meeting is not evidence (docs/milestones/L7.md step L7-3): in a visit in which the Meet screen of a word played, an item that asks that
// word writes nothing at all (no `incorrect`, no tag, no `correct`, no `unsure`), while the child sees the same help and feedback. The same
// item in a visit with no Meet screen (a revisit, or a heritage speaker, who is shown none) is scored as always. Only Russian has Meet screens
// today, so these tests use the Russian pack, built from its source with a test key.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/play/first_meeting.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

void main() {
  late PackContent rus;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    final Uint8List bytes = (await buildPack(languageSource('rus', _languages), key)).bytes;
    rus = PackContent.fromPack(await verifyPack(bytes, publicKey: key.publicKey));
  });

  LessonController open(String lessonId, String? route, List<AttemptRecord> written) => LessonController(
    content: rus,
    lesson: rus.lessons[lessonId]!,
    profileId: 'kid',
    record: (AttemptRecord r) async => written.add(r),
    route: route,
  );

  /// Plays every screen that is on show before the first item: each is touched and left.
  Future<void> pastScreens(LessonController c) async {
    while (c.current.teachScreen) {
      await c.sayItDone();
      c.next();
    }
  }

  String wrongOf(Activity a) {
    final ChoiceActivity choice = a as ChoiceActivity;
    return choice.options.firstWhere((ChoiceOption o) => o.id != choice.correctId).id;
  }

  group('what a Meet screen introduces', () {
    SayItActivity screen(String id) => rus.activities[id]! as SayItActivity;

    test(
      'an item that asks a word met in the visit is a first meeting, and one that asks another word is not',
      () {
        final FirstMeeting meeting = FirstMeeting();
        expect(meeting.asks(rus.activities['rus.a02.01']!), isFalse, reason: 'nothing has been met yet');
        meeting.met(screen('rus.a02.tc01'));
        final Map<String, bool> asked = <String, bool>{
          for (final String id in <String>['rus.a02.01', 'rus.a02.02', 'rus.a02.03', 'rus.a02.04'])
            id: meeting.asks(rus.activities[id]!),
        };
        expect(
          asked.values.where((bool b) => b),
          hasLength(1),
          reason: 'only the word of that one screen: $asked',
        );
        expect(asked['rus.a02.01'], isTrue, reason: 'tc01 is the word мама, which item 01 asks');
      },
    );

    test('a hearing screen of a heritage speaker introduces nothing', () {
      final FirstMeeting meeting = FirstMeeting();
      final SayItActivity hear = rus.activities['rus.a20.th01']! as SayItActivity;
      expect(hear.hear, isTrue);
      meeting.met(hear);
      expect(meeting.asks(rus.activities['rus.a20.01']!), isFalse);
    });

    test('a command that names a body part only by its picture is told by that picture', () {
      final FirstMeeting meeting = FirstMeeting();
      meeting.met(screen('rus.a03.tc01')); // the nose
      expect(meeting.asks(rus.activities['rus.a03.01']!), isTrue, reason: 'show me the nose');
      expect(meeting.asks(rus.activities['rus.a03.02']!), isFalse, reason: 'show me the mouth');
    });
  });

  group('the lesson controller in an introduction visit', () {
    test(
      'a wrong tap on a word just met writes nothing, and the child still gets the help and the feedback',
      () async {
        final List<AttemptRecord> written = <AttemptRecord>[];
        final LessonController c = open('rus.family-1', 'new', written);
        await pastScreens(c);
        final Activity item = c.current;
        final Outcome o = await c.chooseOption(wrongOf(item));
        expect(o.correct, isFalse);
        expect(written, isEmpty, reason: 'no incorrect and no misconception tag');
        expect(c.feedback, FeedbackKind.notYet);
        expect(c.errors, 1, reason: 'the visit goes on as before');
        expect(c.hintShown, greaterThan(0), reason: 'the help is the same');
        expect(c.bubble, isNotEmpty);
        c.dispose();
      },
    );

    test('a right tap on a word just met writes nothing either: neither right nor wrong counts', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('rus.family-1', 'new', written);
      await pastScreens(c);
      final Outcome o = await c.chooseOption((c.current as ChoiceActivity).correctId);
      expect(o.correct, isTrue);
      expect(written, isEmpty);
      expect(c.solved, isTrue);
      expect(c.feedback, FeedbackKind.correct);
      c.dispose();
    });

    test('"I am not sure" writes nothing in an introduction visit', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('rus.family-1', 'new', written);
      await pastScreens(c);
      await c.unsure();
      expect(written, isEmpty);
      c.dispose();
    });

    test('a command that names the word by its picture is a first meeting too (the body)', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('rus.body-1', 'new', written);
      await pastScreens(c);
      await c.chooseOption(wrongOf(c.current));
      expect(written, isEmpty);
      c.dispose();
    });

    test('every item of every lesson with Meet screens that asks a met word is a first meeting', () {
      for (final Lesson l in rus.lessons.values.where((Lesson l) => l.teach.any((TeachSet s) => !s.hear))) {
        final FirstMeeting meeting = FirstMeeting();
        rus.itemsFor(l, route: 'new').where((Activity a) => a.teachScreen).forEach(meeting.met);
        final List<Activity> asked = <Activity>[
          for (final Activity a in rus.itemsOf(l))
            if (!a.unscored && meeting.asks(a)) a,
        ];
        expect(asked, isNotEmpty, reason: '${l.id}: its Meet screens introduce words that its items ask');
      }
    });
  });

  group('everywhere else an answer is scored as always', () {
    test(
      'the same item in a visit with no Meet screen (a revisit) writes the wrong tap with its tag',
      () async {
        final List<AttemptRecord> written = <AttemptRecord>[];
        final LessonController c = LessonController(
          content: rus,
          lesson: Lesson.mission(
            id: 'mission-rus-a-02',
            itemIds: <String>['rus.a02.01'],
            skillIds: <String>['RUS-A-02'],
            celebration: rus.lessons['rus.family-1']!.celebration,
          ),
          profileId: 'kid',
          record: (AttemptRecord r) async => written.add(r),
          route: 'new',
        );
        final Activity item = c.current;
        await c.chooseOption(wrongOf(item));
        expect(written, hasLength(1));
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, isNotEmpty);
        await c.chooseOption((item as ChoiceActivity).correctId);
        expect(written.last.result, 'correct');
        c.dispose();
      },
    );

    test(
      'a heritage speaker is shown no Meet screen, and a wrong tap in the same lesson is scored',
      () async {
        final List<AttemptRecord> written = <AttemptRecord>[];
        final LessonController c = open('rus.family-1', 'heritage', written);
        expect(c.current.teachScreen, isFalse);
        await c.chooseOption(wrongOf(c.current));
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, isNotEmpty);
        c.dispose();
      },
    );

    test('a heritage speaker who hears a word on a hearing screen is still scored on it', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('rus.pairs-1', 'heritage', written);
      while (c.current.teachScreen) {
        c.hearDone();
        c.next();
      }
      await c.chooseOption(wrongOf(c.current));
      expect(written.single.result, 'incorrect');
      c.dispose();
    });
  });
}
