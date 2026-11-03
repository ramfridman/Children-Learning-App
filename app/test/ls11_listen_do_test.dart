// LS11, the listen-and-do template (docs/languages/frame.md section 2.3; L4): the child carries out a command in a scene, five ways:
// touch a glowing part, touch an action button, drag a thing to the target, put the one thing in a place, or do it and touch "done".
// Wrong never shows red, a wrong thing goes back, and the embodied step writes nothing. Fixture course and fake clips, not content.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/listen_do_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>[
  'teddy',
  'table',
  'plate',
  'apple',
  'banana',
  'bread',
  'ball',
  'drum',
  'kite',
];

Map<String, Object?> _command(LangPack p, String mode, {String id = 'doit'}) {
  final String c = p.course;
  switch (mode) {
    case 'hotspots':
      return listenDoJson(
        course: c,
        id: id,
        mode: mode,
        options: <Map<String, Object?>>[
          partOption('o1', at(0.30, 0.05, 0.4, 0.3), label: 'head'),
          partOption('o2', at(0.30, 0.45, 0.4, 0.25), tag: p.tag('lis.sem'), label: 'tummy'),
          partOption('o3', at(0.25, 0.78, 0.5, 0.18), tag: p.tag('lis.guess'), label: 'feet'),
        ],
        correct: 'o1',
      );
    case 'buttons':
      return listenDoJson(
        course: c,
        id: id,
        mode: mode,
        options: <Map<String, Object?>>[
          pictureOption('o1', 'ball'),
          pictureOption('o2', 'drum', tag: p.tag('lis.sem')),
          pictureOption('o3', 'kite', tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      );
    case 'drag':
      return listenDoJson(
        course: c,
        id: id,
        mode: mode,
        picture: 'table',
        target: <String, Object?>{'at': at(0.58, 0.3, 0.38, 0.38), 'sprite': 'asset:plate'},
        options: <Map<String, Object?>>[
          thingOption('o1', 'apple', at(0.02, 0.05, 0.26, 0.26)),
          thingOption('o2', 'banana', at(0.02, 0.37, 0.26, 0.26), tag: p.tag('lis.sem')),
          thingOption('o3', 'bread', at(0.02, 0.69, 0.26, 0.26), tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      );
    case 'place':
      return listenDoJson(
        course: c,
        id: id,
        mode: mode,
        picture: 'table',
        thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.22, 0.22)},
        options: <Map<String, Object?>>[
          partOption('o1', at(0.4, 0.04, 0.5, 0.26), label: 'on'),
          partOption('o2', at(0.4, 0.7, 0.5, 0.26), tag: p.tag('lis.sem'), label: 'under'),
          partOption('o3', at(0.72, 0.36, 0.25, 0.26), tag: p.tag('lis.guess'), label: 'next to'),
        ],
        correct: 'o1',
      );
    default:
      return listenDoJson(course: c, id: id, mode: 'embodied');
  }
}

LangPack _pack(String mode, {String course = 'eng'}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(_command(p, mode));
  return p;
}

Rig<ListenDoSession> _rig(LangPack p) => Rig<ListenDoSession>(
  p,
  'doit',
  (LessonController c, Activity a) => ListenDoSession(c, a as ListenDoActivity),
);

void main() {
  group('the document', () {
    for (final String mode in <String>['hotspots', 'buttons', 'drag', 'place', 'embodied']) {
      test('a $mode command passes the validator and reads as its model', () {
        final LangPack p = _pack(mode);
        expect(_messages(p), isEmpty);
        final ListenDoActivity a = p.content.activities['eng.doit']! as ListenDoActivity;
        expect(a.mode, mode);
        expect(a.embodied, mode == 'embodied');
        expect(a.optionCount, mode == 'embodied' ? 0 : 3);
        expect(a.llmAllowed, isFalse);
        if (mode == 'hotspots') {
          expect(a.options.every((ChoiceOption o) => o.at != null), isTrue);
          expect(a.options.first.at, const Rect.fromLTWH(0.30, 0.05, 0.4, 0.3));
        }
        if (mode == 'drag') expect(a.targetAt, const Rect.fromLTWH(0.58, 0.3, 0.38, 0.38));
        if (mode == 'place') expect(a.thingAt, const Rect.fromLTWH(0.04, 0.4, 0.22, 0.22));
      });
    }

    test('the template is known and its ladder changes the representation at level 2', () {
      expect(supportedTemplates['listen_do'], '1.0');
      expect(allSchemas.containsKey('activity.listen_do'), isTrue);
      expect(HintLadder.problemWith('listen_do'), isNull);
      expect(HintLadder.of('listen_do')!.at(2), HintPicture.friendActs);
    });

    test('a pack of the lands refuses a command', () {
      final SamplePack core = SamplePack();
      final Map<String, Object?> doc = Map<String, Object?>.of(_pack('hotspots').activity('doit'))
        ..remove('course')
        ..['domain'] = 'numbers'
        ..['skills'] = <Object?>[
          <String, Object?>{'id': 'NUM-A-03', 'weight': 1},
        ];
      core.addDocument('activity.doit.json', 'activities', 'doit', doc);
      (core.manifest['templates']! as Map<String, Object?>)['listen_do'] = '1.0';
      expect(
        _run(core).map((Problem x) => '${x.path}: ${x.message}'),
        contains('activity.doit.json › template: listen_do belongs to a language course, not to the lands'),
      );
    });

    test('a step the child does is practice, embodied, with nothing to choose and nothing right', () {
      final LangPack a = _pack('embodied');
      a.activity('doit')['purpose'] = 'learn';
      expect(_messages(a), contains(contains('purpose: a step the child does is never scored')));
      final LangPack b = _pack('embodied');
      b.activity('doit')['representation'] = 'pictorial';
      expect(
        _messages(b),
        contains(contains('representation: what the child does is the representation "embodied"')),
      );
      final LangPack c = _pack('embodied');
      (c.activity('doit')['answer']! as Map<String, Object?>)['correct'] = 'o1';
      expect(_messages(c), contains(contains('answer.correct: a step the child does has no right answer')));
    });

    test('a part with no place, parts that overlap, and a place outside the picture are refused', () {
      final LangPack a = _pack('hotspots');
      (((a.activity('doit')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[1]!
              as Map<String, Object?>)
          .remove('at');
      expect(
        _messages(a),
        contains(contains('answer.options[1].at: a hotspots option is a place in the picture')),
      );
      final LangPack b = _pack('hotspots');
      (((b.activity('doit')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[1]!
          as Map<String, Object?>)['at'] = at(
        0.35,
        0.1,
        0.3,
        0.3,
      );
      expect(
        _messages(b),
        contains(
          contains('answer.options[1].at: overlaps answer.options[0].at: a touch must mean one thing'),
        ),
      );
      final LangPack c = _pack('hotspots');
      (((c.activity('doit')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[2]!
          as Map<String, Object?>)['at'] = at(
        0.8,
        0.8,
        0.4,
        0.4,
      );
      expect(_messages(c), contains(contains('answer.options[2].at: reaches outside the picture')));
    });

    test('a drag needs the target and things with places; a place needs the one thing; a button is an action picture', () {
      final LangPack a = _pack('drag');
      (a.activity('doit')['scene']! as Map<String, Object?>).remove('target');
      expect(
        _messages(a),
        contains(contains('scene.target: a drag mode needs the place the things are taken to')),
      );
      final LangPack b = _pack('place');
      (b.activity('doit')['scene']! as Map<String, Object?>).remove('thing');
      expect(_messages(b), contains(contains('scene.thing: a place mode moves one thing')));
      final LangPack c = _pack('buttons');
      final Map<String, Object?> o =
          ((c.activity('doit')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[0]!
              as Map<String, Object?>;
      o
        ..remove('sprite')
        ..['text'] = 'ball';
      expect(
        _messages(c),
        contains(contains('answer.options[0].sprite: a button is the picture of an action')),
      );
      final LangPack d = _pack('drag');
      (((d.activity('doit')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[0]!
          as Map<String, Object?>)['at'] = at(
        0.6,
        0.3,
        0.2,
        0.2,
      );
      expect(_messages(d), contains(contains('overlaps answer.options[0].at')));
    });

    test('every wrong thing, button or part carries a tag, and every picture must exist', () {
      final LangPack a = _pack('hotspots');
      (((a.activity('doit')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[2]!
              as Map<String, Object?>)
          .remove('misconception');
      expect(_messages(a), contains(contains('a distractor carries the misconception it shows')));
      final LangPack b = _pack('buttons');
      (b.activity('doit')['scene']! as Map<String, Object?>)['picture'] = 'asset:nowhere';
      expect(_messages(b), contains(contains('scene.picture: asset:nowhere is not in the manifest assets')));
    });
  });

  group('touch a part of the picture', () {
    testWidgets('the right part is one correct attempt, the answer is taken, and the lesson goes on', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> r = _rig(_pack('hotspots'));
      await r.pump(t);
      expect(find.byKey(const Key('do-scene-hotspots')), findsOneWidget);
      for (final String id in <String>['o1', 'o2', 'o3']) {
        expect(find.byKey(Key('do-hot-$id')), findsOneWidget, reason: 'every part glows');
      }
      await t.tap(find.byKey(const Key('do-hot-o1')));
      await r.wait(t, 100);
      expect(r.written, <String>['correct:o1']);
      expect(r.session.chosenState, AnswerState.correct);
      await r.wait(t, 1700);
      expect(r.controller.finished, isTrue);
      await r.done(t);
    });

    testWidgets(
      'a wrong part is a tagged mistake with the first hint, never a dead end, and the hints go on to the end',
      (WidgetTester t) async {
        final Rig<ListenDoSession> r = _rig(_pack('hotspots'));
        await r.pump(t);
        await t.tap(find.byKey(const Key('do-hot-o2')));
        await r.wait(t, 100);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        expect(r.session.chosenState, AnswerState.notYet);
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 1);
        expect(r.session.chosenId, isNull, reason: 'the child may try again');
        expect(find.byKey(const Key('do-closeup')), findsNothing);
        // the second mistake: level 2 shows what the command names, close up
        await t.tap(find.byKey(const Key('do-hot-o3')));
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 2);
        expect(r.session.closeUp, isTrue);
        expect(find.byKey(const Key('do-closeup')), findsOneWidget);
        // the third: the demonstration, and then only the right part is taken
        await t.tap(find.byKey(const Key('do-hot-o3')));
        await r.wait(t, 2600);
        expect(r.controller.hintShown, 3);
        expect(r.controller.guided, isTrue);
        expect(r.controller.answerShown, isTrue);
        await t.tap(find.byKey(const Key('do-hot-o2')));
        await r.wait(t, 100);
        expect(r.attempts, hasLength(3), reason: 'a guided item takes only the right answer');
        await t.tap(find.byKey(const Key('do-hot-o1')));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        expect(r.attempts.last.hintLevel, 3);
        await r.done(t);
      },
    );

    testWidgets('the lamp lights the parts one after the other, and marks none', (WidgetTester t) async {
      final Rig<ListenDoSession> r = _rig(_pack('hotspots'));
      await r.pump(t);
      await t.tap(find.byKey(const Key('lesson-hint')));
      await r.wait(t, 100);
      expect(r.controller.hintShown, 1);
      final List<int?> lit = <int?>[];
      for (int i = 0; i < 4; i++) {
        lit.add(r.session.litTile);
        await r.wait(t, 450);
      }
      expect(lit, containsAll(<int?>[0, 1, 2]));
      expect(r.attempts, isEmpty);
      await r.done(t);
    });
  });

  group('touch an action button', () {
    testWidgets('the friend on the stage does the action of the button that was touched', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> r = _rig(_pack('buttons'));
      await r.pump(t);
      expect(r.session.reaction, isNull);
      await t.tap(r.tile('o2'));
      await r.wait(t, 100);
      expect(
        r.session.reaction,
        'asset:drum',
        reason: 'a wrong button shows what the friend did, nothing red',
      );
      expect(r.attempts.single.result, 'incorrect');
      await r.wait(t, 1200);
      expect(r.session.reaction, isNull);
      await t.tap(r.tile('o1'));
      await r.wait(t, 100);
      expect(r.session.reaction, 'asset:ball');
      expect(r.attempts.last.result, 'correct');
      await r.done(t);
    });

    testWidgets('a Hebrew command has its buttons from the right, an English one from the left', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> heb = _rig(_pack('buttons', course: 'heb'));
      await heb.pump(t);
      expect(t.getCenter(heb.tile('o1')).dx, greaterThan(t.getCenter(heb.tile('o3')).dx));
      await heb.done(t);
      final Rig<ListenDoSession> eng = _rig(_pack('buttons'));
      await eng.pump(t);
      expect(t.getCenter(eng.tile('o1')).dx, lessThan(t.getCenter(eng.tile('o3')).dx));
      await eng.done(t);
    });
  });

  group('take a thing to the target', () {
    testWidgets('dragging the right thing to the target puts it there; the answer is one correct attempt', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> r = _rig(_pack('drag'));
      await r.pump(t);
      final Finder piece = find.byKey(const Key('do-piece-o1'));
      final Offset start = t.getCenter(piece);
      await t.drag(piece, t.getCenter(find.byKey(const Key('do-target'))) - start);
      await r.wait(t, 900);
      expect(r.written, <String>['correct:o1']);
      final Offset end = t.getCenter(piece);
      expect(
        (end - t.getCenter(find.byKey(const Key('do-target')))).distance,
        lessThan(4),
        reason: 'it sits in the target',
      );
      await r.done(t);
    });

    testWidgets(
      'a wrong thing dropped on the target goes back to where it was, with its tag and nothing red',
      (WidgetTester t) async {
        final Rig<ListenDoSession> r = _rig(_pack('drag'));
        await r.pump(t);
        final Finder piece = find.byKey(const Key('do-piece-o2'));
        final Offset start = t.getCenter(piece);
        await t.drag(piece, t.getCenter(find.byKey(const Key('do-target'))) - start);
        await r.wait(t, 900);
        expect(r.attempts.single.result, 'incorrect');
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        expect((t.getCenter(piece) - start).distance, lessThan(2), reason: 'a wrong thing goes back');
        await r.done(t);
      },
    );

    testWidgets('the tap path: touch the thing, then the target', (WidgetTester t) async {
      final Rig<ListenDoSession> r = _rig(_pack('drag'));
      await r.pump(t);
      await t.tap(find.byKey(const Key('do-piece-o1')));
      await r.wait(t, 100);
      expect(r.session.selectedId, 'o1');
      expect(find.byKey(const Key('do-lit')), findsOneWidget);
      await t.tap(find.byKey(const Key('do-target')));
      await r.wait(t, 100);
      expect(r.written, <String>['correct:o1']);
      expect(r.session.selectedId, isNull);
      // a touch on the target with nothing chosen does nothing
      await r.done(t);
    });

    testWidgets('the demonstration carries the right thing to the target before the answer is shown', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> r = _rig(_pack('drag'));
      await r.pump(t);
      for (final String id in <String>['o2', 'o3', 'o2']) {
        await t.tap(find.byKey(Key('do-piece-$id')));
        await t.tap(find.byKey(const Key('do-target')));
        await r.wait(t, 1500);
      }
      expect(r.controller.hintShown, 3);
      await r.wait(t, 1800);
      expect(r.session.demoMove, isTrue);
      expect(r.controller.answerShown, isTrue);
      final Offset target = t.getCenter(find.byKey(const Key('do-target')));
      expect((t.getCenter(find.byKey(const Key('do-piece-o1'))) - target).distance, lessThan(4));
      await r.done(t);
    });
  });

  group('put the thing in a place', () {
    testWidgets('a touch on the right place puts the thing there; a wrong place keeps it where it was', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> r = _rig(_pack('place'));
      await r.pump(t);
      final Finder thing = find.byKey(const Key('do-piece-thing'));
      final Offset start = t.getCenter(thing);
      await t.tap(find.byKey(const Key('do-place-o2')));
      await r.wait(t, 900);
      expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
      expect((t.getCenter(thing) - start).distance, lessThan(2));
      await r.wait(t, 700);
      await t.tap(find.byKey(const Key('do-place-o1')));
      await r.wait(t, 900);
      expect(r.attempts.last.result, 'correct');
      expect((t.getCenter(thing) - t.getCenter(find.byKey(const Key('do-place-o1')))).distance, lessThan(4));
      await r.done(t);
    });

    testWidgets('dragging the thing to the right place is the answer', (WidgetTester t) async {
      final Rig<ListenDoSession> r = _rig(_pack('place', course: 'heb'));
      await r.pump(t);
      final Finder thing = find.byKey(const Key('do-piece-thing'));
      await t.drag(thing, t.getCenter(find.byKey(const Key('do-place-o1'))) - t.getCenter(thing));
      await r.wait(t, 900);
      expect(r.written, <String>['correct:o1']);
      await r.done(t);
    });
  });

  group('do it and touch "done"', () {
    testWidgets('is practice: the warm line, no attempt written, and the lesson goes on', (
      WidgetTester t,
    ) async {
      final Rig<ListenDoSession> r = _rig(_pack('embodied'));
      await r.pump(t);
      expect(find.byKey(const Key('do-done')), findsOneWidget);
      await t.tap(find.byKey(const Key('do-done')));
      await r.wait(t, 100);
      expect(r.controller.bubble, 'נָכוֹן!');
      await r.wait(t, 1700);
      expect(r.controller.finished, isTrue);
      expect(r.attempts, isEmpty, reason: 'what the child does is never counted alone');
      await r.done(t);
    });
  });

  test('the new files have no timer, countdown or streak (the child space has none)', () {
    final RegExp banned = RegExp('timer|countdown|streak|stopwatch', caseSensitive: false);
    for (final String line in File('lib/play/listen_do_session.dart').readAsLinesSync()) {
      if (line.trimLeft().startsWith('//')) continue;
      expect(banned.hasMatch(line), isFalse, reason: line);
    }
  });
}
