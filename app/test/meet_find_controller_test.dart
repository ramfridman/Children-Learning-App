// L7-4 on the real English lesson 1 (`eng.greet-1`, re-cut as docs/milestones/L7.md section 3.1 says): the Meet screens stand where the lesson
// says (`before`), a set is one socket of the trail, an item names its word, a lesson played again is no first meeting, and a picture choice
// whose pictures name their words says "and where is ...?" on the first wrong tap and shows no hint picture with it. The pack is built from
// the course's source with a test key.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/play/first_meeting.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/temp_dir.dart';

const String _languages = '../content/languages';

void main() {
  late PackContent eng;
  late PackKey key;

  setUpAll(() async {
    key = await newTestKey();
    final Uint8List bytes = (await buildPack(languageSource('eng', _languages), key)).bytes;
    eng = PackContent.fromPack(await verifyPack(bytes, publicKey: key.publicKey));
  });

  LessonController open(
    String lessonId,
    List<AttemptRecord> written, {
    String? route = 'new',
    bool introVisit = true,
    PackContent? pack,
  }) {
    final PackContent content = pack ?? eng;
    return LessonController(
      content: content,
      lesson: content.lessons[lessonId]!,
      profileId: 'kid',
      record: (AttemptRecord r) async => written.add(r),
      route: route,
      introVisit: introVisit,
    );
  }

  Future<void> pastScreens(LessonController c) async {
    while (c.current.teachScreen) {
      c.next();
    }
  }

  String wrongOf(Activity a) {
    final ChoiceActivity choice = a as ChoiceActivity;
    return choice.options.firstWhere((ChoiceOption o) => o.id != choice.correctId).id;
  }

  group('the shape of lesson 1', () {
    test('the Meet screens come first, then the Find, then the Use items', () {
      final List<Activity> items = eng.itemsFor(eng.lessons['eng.greet-1']!, route: 'new');
      expect(
        <String>[for (final Activity a in items) a.id],
        <String>[
          'eng.a01.tc01',
          'eng.a01.tc02',
          'eng.a01.i01',
          'eng.a01.i02',
          'eng.a01.i05',
          'eng.a01.i12',
          'eng.a01.s01',
          'eng.a01.i07',
          'eng.a01.r01',
        ],
      );
    });

    test('a heritage speaker is shown no Meet screen', () {
      final List<Activity> items = eng.itemsFor(eng.lessons['eng.greet-1']!, route: 'heritage');
      expect(items.where((Activity a) => a.teachScreen), isEmpty);
      expect(items.first.id, 'eng.a01.i01');
    });

    test('a Meet screen knows its set, the Hebrew meaning it says once, and carries no chip of its own', () {
      final SayItActivity first = eng.activities['eng.a01.tc01']! as SayItActivity;
      final SayItActivity second = eng.activities['eng.a01.tc02']! as SayItActivity;
      expect(first.meetScreen, isTrue);
      expect(first.meet!.first, isTrue);
      expect(first.meet!.earlier, isEmpty);
      expect(second.meet!.first, isFalse);
      expect(second.meet!.earlier.map((MeetWord w) => w.clip), <String>['vo:eng.en_hello']);
      expect(first.meet!.meaning!.vo, 'vo:eng.he_hint_hebrew');
      expect(first.meet!.meaning!.target, 'vo:eng.he_gl_hello');
      expect(first.meet!.meaning!.caption, 'בְּעִבְרִית: שָׁלוֹם');
      expect(
        first.firstBeat.vo,
        'vo:eng.en_hello',
        reason: 'with no opener the screen opens on the word alone',
      );
      expect(first.promptLine.show, isNull, reason: 'a Band A skill prints no word');
    });

    test('a set is one socket of the trail, filled at its last screen', () {
      final LessonController c = open('eng.greet-1', <AttemptRecord>[]);
      expect(c.items.length, 9);
      expect(c.trailLength, 8, reason: 'two Meet screens are one socket, and seven items');
      expect(c.trailDone, 0);
      c.next();
      expect(c.index, 1);
      expect(c.trailDone, 0, reason: 'the second screen of the set: the socket is not full');
      c.next();
      expect(c.trailDone, 1, reason: 'the set is behind the child');
      c.next();
      expect(c.trailDone, 2);
      c.dispose();
    });

    test('a Meet screen opens on its first beat and the replay button says nothing of its own', () {
      final LessonController c = open('eng.greet-1', <AttemptRecord>[]);
      expect(c.voice, 'vo:eng.en_hello');
      expect(c.noHelp, isTrue, reason: 'no lamp, no "show me" on a Meet screen');
      c.dispose();
    });
  });

  group('a Meet set may stand anywhere in a lesson', () {
    late Directory dir;

    setUp(() {
      final Directory from = languageSource('eng', _languages);
      dir = Directory.systemTemp.createTempSync('nn_meet_');
      for (final FileSystemEntity e in from.listSync()) {
        if (e is File) e.copySync('${dir.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
      }
    });
    tearDown(() => removeTempDir(dir));

    void change(String file, void Function(Map<String, Object?> doc) edit) {
      final File f = File('${dir.path}${Platform.pathSeparator}$file');
      final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      edit(doc);
      f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');
    }

    Future<PackContent> built() async {
      final Uint8List bytes = (await buildPack(dir, key)).bytes;
      return PackContent.fromPack(await verifyPack(bytes, publicKey: key.publicKey));
    }

    Future<String> refused() async {
      try {
        await buildPack(dir, key);
      } on BuildFailed catch (e) {
        return e.problems.map((Problem p) => '$p').join('\n');
      }
      fail('the broken source was signed');
    }

    test('itemsFor puts the screens in front of the item `before` names', () async {
      change('lesson.eng.greet-1.json', (Map<String, Object?> l) {
        ((l['teach']! as List<Object?>).first! as Map<String, Object?>)['before'] = 'eng.a01.i05';
      });
      final PackContent pack = await built();
      expect(
        <String>[for (final Activity a in pack.itemsFor(pack.lessons['eng.greet-1']!, route: 'new')) a.id],
        <String>[
          'eng.a01.i01',
          'eng.a01.i02',
          'eng.a01.tc01',
          'eng.a01.tc02',
          'eng.a01.i05',
          'eng.a01.i12',
          'eng.a01.s01',
          'eng.a01.i07',
          'eng.a01.r01',
        ],
      );
    });

    test('a set that names no item stands before the first', () async {
      final PackContent pack = await built();
      expect(pack.itemsFor(pack.lessons['eng.greet-1']!, route: 'new').first.id, 'eng.a01.tc01');
    });

    test('a `before` that is not an item of the lesson is refused with the reason', () async {
      change('lesson.eng.greet-1.json', (Map<String, Object?> l) {
        ((l['teach']! as List<Object?>).first! as Map<String, Object?>)['before'] = 'eng.a01.i03';
      });
      expect(
        await refused(),
        allOf(
          contains('lesson.eng.greet-1.json'),
          contains('teach[0].before: "eng.a01.i03" is not an item of the lesson'),
        ),
      );
    });

    test('the data of a Meet screen is held to its set: a screen at place 0 has no word before it', () async {
      change('activity.eng.a01.tc02.json', (Map<String, Object?> a) {
        ((a['say']! as Map<String, Object?>)['meet']! as Map<String, Object?>)['position'] = 0;
      });
      expect(await refused(), contains('a screen at place 0 has the 0 words before it in its set, not 1'));
    });

    test('only a teach screen has Meet data', () async {
      change('activity.eng.a01.s01.json', (Map<String, Object?> a) {
        (a['say']! as Map<String, Object?>)['meet'] = <String, Object?>{'position': 0, 'size': 1};
      });
      expect(await refused(), contains('only a teach screen of the new learner is a Meet screen'));
    });
  });

  group('an item names its word', () {
    test('a find item asks the word its prompt ends with, and a command names it with `asks`', () {
      final FirstMeeting meeting = FirstMeeting()..met(eng.activities['eng.a01.tc01']! as SayItActivity);
      expect(askedWords(eng.activities['eng.a01.i01']!), <String>{'vo:eng.en_hello'});
      expect(meeting.asks(eng.activities['eng.a01.i01']!), isTrue);
      expect(
        meeting.asks(eng.activities['eng.a01.i02']!),
        isFalse,
        reason: 'goodbye has not been met by this screen',
      );
    });

    test("a puppet's bubble asks the word of its right answer, not the puppet's line", () {
      final FirstMeeting meeting = FirstMeeting()..met(eng.activities['eng.a01.tc01']! as SayItActivity);
      expect(meeting.asks(eng.activities['eng.a01.i07']!), isTrue, reason: 'the answer is "hello"');
    });
  });

  group('first meeting and a lesson played again', () {
    test('in the introduction visit a wrong tap on a word just met writes nothing', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('eng.greet-1', written);
      await pastScreens(c);
      await c.chooseOption(wrongOf(c.current));
      expect(written, isEmpty);
      c.dispose();
    });

    test(
      'the lesson played again is a later visit: its Meet screens come again, and the same tap is scored',
      () async {
        final List<AttemptRecord> written = <AttemptRecord>[];
        final LessonController c = open('eng.greet-1', written, introVisit: false);
        expect(c.current.teachScreen, isTrue, reason: 're-teaching is cheap: the screens come again');
        await pastScreens(c);
        await c.chooseOption(wrongOf(c.current));
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'eng.lis.sem');
        c.dispose();
      },
    );

    test('a say step on a Meet screen writes nothing when the microphone hears the child', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('eng.greet-1', written);
      await c.sayHeard();
      expect(written, isEmpty, reason: 'the microphone of a Meet screen is feedback only, never evidence');
      expect(c.bubble, isNotEmpty);
      c.dispose();
    });
  });

  group('the first wrong tap of a picture choice whose pictures name their words', () {
    test('every picture option of the Find items names its word clip, and the items ask where', () {
      for (final String id in <String>['i01', 'i02', 'i05', 'i12']) {
        final TapAnswerActivity a = eng.activities['eng.a01.$id']! as TapAnswerActivity;
        expect(a.options.every((ChoiceOption o) => o.sprite != null && o.clip != null), isTrue, reason: id);
        expect(a.askWhere, isTrue, reason: id);
        expect(a.options, hasLength(2), reason: 'the first Find has two choices');
      }
    });

    test(
      'says "and where is" and the target, shows no hint picture, and the replay button asks the line again',
      () async {
        final LessonController c = open('eng.greet-1', <AttemptRecord>[], introVisit: false);
        await pastScreens(c);
        await c.chooseOption(wrongOf(c.current));
        expect(c.voice, 'vo:eng.he_fb_where');
        expect(c.voiceTarget, 'vo:eng.en_hello');
        expect(c.hintShown, 0, reason: 'no hint picture with the first wrong tap');
        expect(c.guided, isFalse);
        expect(c.askedLine?.vo, 'vo:eng.he_fb_where');
        expect(c.feedback, FeedbackKind.notYet);
        c.dispose();
      },
    );

    test('with two choices the second wrong tap leads to the guided help (level 3)', () async {
      final LessonController c = open('eng.greet-1', <AttemptRecord>[], introVisit: false);
      await pastScreens(c);
      final String wrong = wrongOf(c.current);
      await c.chooseOption(wrong);
      await c.chooseOption(wrong);
      expect(c.hintShown, 3);
      expect(c.guided, isTrue);
      c.dispose();
    });

    test('an item whose pictures do not all name their words keeps the old first help', () {
      for (final String id in <String>['i04', 'i09']) {
        expect((eng.activities['eng.a01.$id']! as TapAnswerActivity).askWhere, isFalse, reason: id);
      }
    });
  });
}
