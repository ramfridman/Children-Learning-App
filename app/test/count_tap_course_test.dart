// Count-and-tap in a course (docs/languages/frame.md section 2.2): the counting taps are practice and never scored, and the one
// scored step, "how many?", is answered on sound buttons that each play a number word. Fixture course and fake clips.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/option_faces.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

String _file(LangPack p, String id) => 'activity.${p.course}.$id.json';

Matcher _refused(String path, String message) => predicate<List<Problem>>(
  (List<Problem> ps) => ps.any((Problem x) => x.path == path && x.message.contains(message)),
  'refuses "$path": $message',
);

/// A count of three objects with its number clips and three sound buttons.
LangPack _counting([String course = 'eng']) {
  final LangPack p = LangPack(course);
  p.add(
    countJson(
      course: course,
      id: 'cnt',
      count: 3,
      clips: <String>['vo:$course.n.one', 'vo:$course.n.two', 'vo:$course.n.three'],
      options: <Map<String, Object?>>[
        soundOption('o1', 'vo:$course.n.three', value: 3),
        soundOption('o2', 'vo:$course.n.two', value: 2, tag: p.tag('lis.numword')),
        soundOption('o3', 'vo:$course.n.four', value: 4, tag: p.tag('lis.numword')),
      ],
      correct: 'o1',
      answerTarget: 'vo:$course.n.howmany',
    ),
  );
  return p;
}

Map<String, Object?> _scene(Map<String, Object?> a) =>
    (a['scene']! as Map<String, Object?>)['objects']! as Map<String, Object?>;

/// A session of the count of [p], with what it writes and the clips it asks for.
class CountRig {
  CountRig(LangPack p, {Map<String, Object?> Function(Map<String, Object?>)? change}) {
    final PackContent content = p.content;
    activity = content.activities['${p.course}.cnt']! as CountTapActivity;
    controller = LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'one',
        itemIds: <String>[activity.id],
        skillIds: <String>[activity.skillId],
        celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async => attempts.add(r),
    );
    session = CountTapSession(controller, activity)
      ..playClips = (List<String> ids, {bool replace = false}) {
        heard.add('${replace ? 'now' : 'after'} ${ids.join(' ')}');
      };
  }

  late final CountTapActivity activity;
  late final LessonController controller;
  late final CountTapSession session;
  final List<String> heard = <String>[];
  final List<AttemptRecord> attempts = <AttemptRecord>[];

  Future<void> pump(WidgetTester t, {Size size = const Size(852, 393)}) async {
    addTearDown(() {
      if (!session.disposed) session.dispose();
    });
    await pumpScreen(
      t,
      Builder(
        builder: (BuildContext c) {
          final ActivitySpec spec = ActivitySpec.of(boardClassFor(size));
          return ActivityFrame(
            bubbleText: controller.bubble,
            stage: (Size room) => session.buildStage(c, room, spec),
            tiles: session.buildTiles(c, spec),
            trailTotal: 3,
            trailDone: 1,
            onHome: () {},
          );
        },
      ),
      size: size,
      band: Band.a,
    );
  }

  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    session.dispose();
  }

  Future<void> count(WidgetTester t, Iterable<int> objects) async {
    for (final int i in objects) {
      await t.tap(find.byKey(Key('butterfly-$i')));
      await t.pump(const Duration(milliseconds: 700));
    }
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('the pack of a count in a course', () {
    for (final String c in <String>['eng', 'rus', 'heb']) {
      test('$c: a count with number clips and sound buttons is valid', () {
        expect(_run(_counting(c).pack), isEmpty);
      });
    }

    test('the model holds the number clips of the taps and the clip of each button', () {
      final CountTapActivity a = _counting().content.activities['eng.cnt']! as CountTapActivity;
      expect(a.clips, <String>['vo:eng.n.one', 'vo:eng.n.two', 'vo:eng.n.three']);
      expect(a.options.every((ChoiceOption o) => o.soundOnly), isTrue);
      expect(a.answerPrompt.target, 'vo:eng.n.howmany');
      expect(a.isLanguage, isTrue);
    });

    test('a count that says no number word for its taps is refused', () {
      final LangPack p = _counting();
      _scene(p.activity('cnt')).remove('clips');
      expect(
        _run(p.pack),
        _refused('${_file(p, 'cnt')} › scene.objects.clips', 'a number word for each tap'),
      );
    });

    test('one clip for each object, no more and no fewer', () {
      final LangPack p = _counting();
      (_scene(p.activity('cnt'))['clips']! as List<Object?>).removeLast();
      expect(_run(p.pack), _refused('${_file(p, 'cnt')} › scene.objects.clips', '2 clips for 3 objects'));
    });

    test('a counting error carries no tag in a course: not a language tag, and not a core one', () {
      final LangPack p = _counting();
      p.activity('cnt')['traceClassifiers'] = <Object?>[
        <String, Object?>{'when': 'same_object_tapped_twice', 'misconception': 'eng.lis.sem'},
      ];
      expect(_run(p.pack), _refused('${_file(p, 'cnt')} › traceClassifiers', 'maths, not language'));
      p.activity('cnt')['traceClassifiers'] = <Object?>[
        <String, Object?>{'when': 'same_object_tapped_twice', 'misconception': 'M-CNT-DOUBLE'},
      ];
      expect(_run(p.pack), _refused('${_file(p, 'cnt')} › traceClassifiers', 'maths, not language'));
    });

    test('the scored step is on sound buttons: an option with no clip is refused', () {
      final LangPack p = _counting();
      final List<Object?> options =
          (p.activity('cnt')['answer']! as Map<String, Object?>)['options']! as List<Object?>;
      (options[1]! as Map<String, Object?>).remove('clip');
      expect(_run(p.pack), _refused('${_file(p, 'cnt')} › answer.options[1].clip', 'sound buttons'));
    });

    test('the distractors of "how many?" are tagged like every other', () {
      final LangPack p = _counting();
      final List<Object?> options =
          (p.activity('cnt')['answer']! as Map<String, Object?>)['options']! as List<Object?>;
      (options[2]! as Map<String, Object?>).remove('misconception');
      expect(
        _run(p.pack),
        _refused('${_file(p, 'cnt')} › answer.options[2].misconception', 'every distractor is tagged'),
      );
    });

    test('a count of the lands holds no number clips and no sound button', () {
      final SamplePack p = SamplePack();
      final Map<String, Object?> count = p.doc(countFile);
      _scene(count)['clips'] = <Object?>['vo:fb.again', 'vo:fb.again', 'vo:fb.again'];
      ((count['answer']! as Map<String, Object?>)['options']! as List<Object?>)
              .cast<Map<String, Object?>>()
              .first['clip'] =
          'vo:fb.again';
      final List<Problem> ps = _run(p);
      expect(ps, _refused('$countFile › scene.objects.clips', 'belongs to a language course'));
      expect(ps, _refused('$countFile › answer.options[0].clip', 'belongs to a language course'));
    });
  });

  group('the counting taps are practice', () {
    testWidgets('each tap plays the next number word, and nothing is written', (WidgetTester t) async {
      final CountRig r = CountRig(_counting());
      await r.pump(t);
      await r.count(t, <int>[0, 1, 2]);
      expect(r.heard, <String>['now vo:eng.n.one', 'now vo:eng.n.two', 'now vo:eng.n.three']);
      expect(r.attempts, isEmpty, reason: 'the counting taps are never scored');
      expect(r.session.answering, isTrue);
      await r.done(t);
    });

    testWidgets('the same object twice lights it and starts the count again: no evidence, no tag', (
      WidgetTester t,
    ) async {
      final CountRig r = CountRig(_counting());
      await r.pump(t);
      await t.tap(find.byKey(const Key('butterfly-0')));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byKey(const Key('butterfly-0')));
      await t.pump(const Duration(milliseconds: 100));
      expect(r.session.wiggling, 0, reason: 'the object lights');
      expect(r.session.touchedTwice, isFalse, reason: 'it is maths, not language: nothing is kept of it');
      await t.pump(const Duration(milliseconds: 700));
      expect(r.session.counted, isEmpty, reason: 'the count starts again');
      expect(r.attempts, isEmpty);
      await r.count(t, <int>[0, 1, 2]);
      expect(r.session.answering, isTrue);
      expect(
        r.heard.where((String h) => h == 'now vo:eng.n.one'),
        hasLength(2),
        reason: 'the first number again',
      );
      await r.done(t);
    });

    testWidgets('a core tag on the count, if it ever got past the validator, is never written', (
      WidgetTester t,
    ) async {
      final LangPack p = _counting();
      p.activity('cnt')['traceClassifiers'] = <Object?>[
        <String, Object?>{'when': 'same_object_tapped_twice', 'misconception': 'M-CNT-DOUBLE'},
      ];
      final CountRig r = CountRig(p);
      await r.pump(t);
      await t.tap(find.byKey(const Key('butterfly-0')));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byKey(const Key('butterfly-0')));
      await t.pump(const Duration(milliseconds: 800));
      await r.count(t, <int>[0, 1, 2]);
      await t.tap(find.byKey(const Key('tile-o2')));
      await t.pump(const Duration(milliseconds: 50));
      expect(
        r.attempts.single.misconceptionTag,
        'eng.lis.numword',
        reason: 'only the number word chosen is evidence',
      );
      await r.done(t);
    });
  });

  group('how many? is the scored step', () {
    testWidgets('the options are sound buttons: a speaker and no numeral, no dots, no picture', (
      WidgetTester t,
    ) async {
      final CountRig r = CountRig(_counting());
      await r.pump(t);
      await r.count(t, <int>[0, 1, 2]);
      expect(find.byType(SoundFace), findsNWidgets(3));
      for (final String id in <String>['o1', 'o2', 'o3']) {
        expect(
          find.descendant(of: find.byKey(Key('tile-$id')), matching: find.byType(Text)),
          findsNothing,
          reason: 'a numeral could be answered without the number word',
        );
      }
      expect(t.getSemantics(find.byKey(const Key('tile-o1'))).label, isNot(contains('3')));
      await r.done(t);
    });

    testWidgets(
      'a button plays its number word as it answers; a wrong one writes its tag, once, and does not recount',
      (WidgetTester t) async {
        final CountRig r = CountRig(_counting());
        await r.pump(t);
        await r.count(t, <int>[0, 1, 2]);
        r.heard.clear();
        await t.tap(find.byKey(const Key('tile-o2')));
        await t.pump(const Duration(milliseconds: 50));
        expect(r.heard, <String>['now vo:eng.n.two']);
        expect(r.attempts, hasLength(1));
        expect(r.attempts.single.result, 'incorrect');
        expect(r.attempts.single.misconceptionTag, 'eng.lis.numword');
        expect(
          r.attempts.single.response,
          'o2',
          reason: 'an option id: no number word, no number in the response',
        );
        await t.pump(const Duration(milliseconds: 1200));
        expect(r.session.answering, isTrue, reason: 'the count is done: the choice stays on offer');
        expect(r.session.counted, hasLength(3));
        await t.tap(find.byKey(const Key('tile-o1')));
        await t.pump(const Duration(milliseconds: 50));
        expect(r.attempts.last.result, 'correct');
        expect(r.attempts, hasLength(2), reason: 'the choices are the only evidence');
        await r.done(t);
      },
    );

    testWidgets('a hint plays all the buttons again, after the hint\'s own line', (WidgetTester t) async {
      final CountRig r = CountRig(_counting());
      await r.pump(t);
      await r.count(t, <int>[0, 1, 2]);
      r.heard.clear();
      r.controller.showHint();
      await t.pump(const Duration(milliseconds: 50));
      expect(r.heard, <String>['after vo:eng.n.three vo:eng.n.two vo:eng.n.four']);
      await t.pump(const Duration(seconds: 5));
      await r.done(t);
    });

    testWidgets('"how many?" is asked in two clips once the counting is done', (WidgetTester t) async {
      final CountRig r = CountRig(_counting());
      await r.pump(t);
      await r.count(t, <int>[0, 1]);
      expect(
        r.controller.voiceTarget,
        isNull,
        reason: 'not yet: the question is asked when the last one is counted',
      );
      await r.count(t, <int>[2]);
      expect(r.controller.voice, 'vo:eng.cnt.howmany');
      expect(r.controller.voiceTarget, 'vo:eng.n.howmany');
      await r.done(t);
    });

    testWidgets(
      'the buttons follow the course: left to right in English and Russian, right to left in Hebrew',
      (WidgetTester t) async {
        for (final (String course, bool leftFirst) in <(String, bool)>[
          ('eng', true),
          ('rus', true),
          ('heb', false),
        ]) {
          final CountRig r = CountRig(_counting(course));
          await r.pump(t);
          await r.count(t, <int>[0, 1, 2]);
          final double x1 = t.getCenter(find.byKey(const Key('tile-o1'))).dx;
          final double x2 = t.getCenter(find.byKey(const Key('tile-o2'))).dx;
          expect(x1 < x2, leftFirst, reason: course);
          await r.done(t);
        }
      },
    );
  });
}
