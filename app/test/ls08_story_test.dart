// LS08, the story template (docs/languages/frame.md section 2.3; L4): a picture book of a few pages, narrated page by page, the child
// turns the pages and may touch a thing to hear its word. `listen` is only heard and writes nothing; `dialogic` stops to ask a
// scored question with the hint ladder of the template. Fixture course and fake clips, not content.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/story_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['ball_red', 'cat', 'duck', 'frog', 'dog'];

/// "Bounce, Ball!" (English batch ENG-A-15), five pages; the dialogic pause comes after page 2 (index 1), before the duck.
Map<String, Object?> _bounce(
  LangPack p, {
  String id = 'bounce',
  bool dialogic = true,
  int pauseAfter = 1,
  List<Map<String, Object?>>? options,
}) {
  final String c = p.course;
  return storyJson(
    course: c,
    id: id,
    pages: <Map<String, Object?>>[
      for (final (int i, String pic) in _pictures.indexed)
        storyPage(
          pic,
          <String>['vo:$c.st.p${i + 1}', if (i == 2) 'vo:$c.st.p3b'],
          words: <Map<String, Object?>>[hotWord('vo:$c.w.${pic.replaceAll('_', '')}')],
        ),
    ],
    pauseAfter: dialogic ? pauseAfter : null,
    options: !dialogic
        ? null
        : options ??
              <Map<String, Object?>>[
                pictureOption('o1', 'duck', clip: 'vo:$c.w.duck'),
                pictureOption('o2', 'cat', tag: p.tag('lis.sem')),
                pictureOption('o3', 'frog', tag: p.tag('lis.guess')),
              ],
    correct: dialogic ? 'o1' : null,
  );
}

LangPack _pack({String course = 'eng', bool dialogic = true}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(_bounce(p, dialogic: dialogic));
  return p;
}

Rig<StorySession> _rig(LangPack p, {String id = 'bounce'}) =>
    Rig<StorySession>(p, id, (LessonController c, Activity a) => StorySession(c, a as StoryActivity));

void main() {
  group('the document', () {
    test('a listen story and a dialogic story pass the validator', () {
      expect(_messages(_pack(dialogic: false)), isEmpty);
      expect(_messages(_pack()), isEmpty);
      final StoryActivity a = _pack().content.activities['eng.bounce']! as StoryActivity;
      expect(a.pages, hasLength(5));
      expect(a.pages[2].clips, <String>['vo:eng.st.p3', 'vo:eng.st.p3b']);
      expect(a.pauseAfter, 1);
      expect(a.dialogic, isTrue);
      expect(a.optionCount, 3);
      expect(a.llmAllowed, isFalse);
      expect(a.engineTags, <String>{'eng.lis.sem', 'eng.lis.guess'});
    });

    test('the template is known, versioned, and its ladder changes the representation at level 2', () {
      expect(
        supportedTemplates['story'],
        '1.1',
        reason: '1.1 adds the print-direction modes zones and follow',
      );
      expect(activitySchemaFor('story'), isNotNull);
      expect(allSchemas.containsKey('activity.story'), isTrue);
      expect(HintLadder.problemWith('story'), isNull);
      expect(HintLadder.of('story')!.pictures, <HintPicture>[
        HintPicture.replayPart,
        HintPicture.pagesInRow,
        HintPicture.demonstration,
      ]);
    });

    test('a story belongs to a language course: a pack of the lands refuses it', () {
      final SamplePack core = SamplePack();
      final LangPack p = _pack();
      final Map<String, Object?> story = Map<String, Object?>.of(p.activity('bounce'))
        ..['id'] = 'bounce'
        ..remove('course')
        ..['domain'] = 'numbers'
        ..['skills'] = <Object?>[
          <String, Object?>{'id': 'NUM-A-03', 'weight': 1},
        ];
      core.addDocument('activity.bounce.json', 'activities', 'bounce', story);
      (core.manifest['templates']! as Map<String, Object?>)['story'] = '1.0';
      expect(
        _run(core).map((Problem x) => '${x.path}: ${x.message}'),
        contains('activity.bounce.json › template: story belongs to a language course, not to the lands'),
      );
    });

    test('a pause that is not a page, a missing question and an option outside the room are refused', () {
      final LangPack a = LangPack()..addPictures(_pictures);
      a.add(_bounce(a, pauseAfter: 7));
      expect(
        _messages(a),
        contains(startsWith('activity.eng.bounce.json › answer.pauseAfter: must be a page')),
      );

      final LangPack b = _pack();
      ((b.activity('bounce')['answer']! as Map<String, Object?>)).remove('question');
      expect(_messages(b), contains(startsWith('activity.eng.bounce.json › answer.question')));

      final LangPack c = _pack();
      final Map<String, Object?> page =
          ((c.activity('bounce')['scene']! as Map<String, Object?>)['pages']! as List<Object?>)[0]!
              as Map<String, Object?>;
      ((page['words']! as List<Object?>)[0]! as Map<String, Object?>)['at'] = <String, Object?>{
        'x': 0.9,
        'y': 0.1,
        'w': 0.3,
        'h': 0.3,
      };
      expect(_messages(c), contains(contains('scene.pages[0].words[0].at: reaches outside the picture')));
    });

    test('a story that is only heard is practice with nothing to answer', () {
      final LangPack p = _pack(dialogic: false);
      p.activity('bounce')['purpose'] = 'learn';
      expect(_messages(p), contains(contains('purpose: a story that is only heard is never scored')));
      final LangPack q = _pack(dialogic: false);
      (q.activity('bounce')['answer']! as Map<String, Object?>)['pauseAfter'] = 1;
      expect(_messages(q), contains(contains('answer.pauseAfter: a story that is only heard has no pause')));
    });

    test('every distractor of a pause is tagged, and the sound and the pictures must exist', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      p.add(
        _bounce(
          p,
          options: <Map<String, Object?>>[
            pictureOption('o1', 'duck'),
            pictureOption('o2', 'cat'),
            pictureOption('o3', 'frog', tag: p.tag('lis.guess')),
          ],
        ),
      );
      expect(
        _messages(p),
        contains(contains('answer.options[1].misconception: a distractor carries the misconception')),
      );
      final LangPack q = _pack();
      ((q.activity('bounce')['scene']! as Map<String, Object?>)['pages']! as List<Object?>)[0] = storyPage(
        'nothing',
        <String>['vo:eng.st.p1'],
      );
      expect(_messages(q), contains(contains('is not in the manifest assets')));
    });

    test(
      'a pause of two options is a two-choice item: one tagged distractor, and the rules of section 2.3 hold',
      () {
        final LangPack p = LangPack()..addPictures(_pictures);
        p.add(
          _bounce(
            p,
            options: <Map<String, Object?>>[
              pictureOption('o1', 'duck'),
              pictureOption('o2', 'cat', tag: p.tag('lis.sem')),
            ],
          ),
        );
        final List<String> m = _messages(p);
        // Alone, a 2-choice skill with only 2-choice items needs items with three; the validator says so.
        expect(m, contains(contains('has only items with two choices and is not binary')));
      },
    );
  });

  group('a story that is only heard', () {
    testWidgets('narrates each page when it comes up, turns on the arrow, says the word of a touched thing', (
      WidgetTester t,
    ) async {
      final Rig<StorySession> r = _rig(_pack(dialogic: false));
      await r.pump(t);
      await r.wait(t, 200);
      expect(r.heard.calls, <String>['after vo:eng.st.p1']);
      expect(find.byKey(const Key('story-page-0')), findsOneWidget);
      // a touch on a thing in the picture says its word and rings it
      await t.tap(find.byKey(const Key('story-word-0')));
      await r.wait(t, 100);
      expect(r.heard.calls.last, 'now vo:eng.w.ballred');
      expect(r.session.litWord, 0);
      await r.wait(t, 800);
      expect(r.session.litWord, isNull);
      // the arrow turns the page: its narration (two clips on page 3) cuts in
      await t.tap(find.byKey(const Key('story-turn')));
      await r.wait(t, 100);
      expect(r.session.page, 1);
      expect(r.heard.calls.last, 'now vo:eng.st.p2');
      await t.tap(find.byKey(const Key('story-turn')));
      await r.wait(t, 100);
      expect(r.heard.calls.last, 'now vo:eng.st.p3 vo:eng.st.p3b');
      await r.done(t);
    });

    testWidgets('the replay button plays the page again and says no line of its own', (WidgetTester t) async {
      final Rig<StorySession> r = _rig(_pack(dialogic: false));
      await r.pump(t);
      await r.wait(t, 200);
      final int nonce = r.controller.voiceNonce;
      await t.tap(find.byKey(const Key('lesson-replay')));
      await r.wait(t, 100);
      expect(r.controller.voiceNonce, nonce, reason: 'the guide says nothing; the page is told again');
      expect(r.heard.calls.last, 'now vo:eng.st.p1');
      await r.done(t);
    });

    testWidgets(
      'the last page ends in a tick; the story is practice: nothing is written, and the lesson goes on',
      (WidgetTester t) async {
        final Rig<StorySession> r = _rig(_pack(dialogic: false));
        await r.pump(t);
        for (int i = 0; i < 4; i++) {
          await t.tap(find.byKey(const Key('story-turn')));
          await r.wait(t, 100);
        }
        expect(r.session.page, 4);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        await t.tap(find.byKey(const Key('story-turn')));
        await r.wait(t, 100);
        expect(r.controller.solved, isTrue);
        expect(r.controller.bubble, 'נָכוֹן!');
        await r.wait(t, 1800);
        expect(r.controller.finished, isTrue);
        expect(
          r.attempts,
          isEmpty,
          reason: 'a story that is only heard is practice: no attempt, no evidence',
        );
        await r.done(t);
      },
    );

    testWidgets('no help and no tiles: a story that is heard has no question', (WidgetTester t) async {
      final Rig<StorySession> r = _rig(_pack(dialogic: false));
      await r.pump(t);
      expect(find.byKey(const Key('answer-tile')), findsNothing);
      expect(
        r.session.buildTiles(t.element(find.byKey(const Key('story-stage'))), ActivitySpec.phone),
        isNull,
      );
      await r.done(t);
    });

    testWidgets('a Hebrew story is turned toward the left, an English one toward the right', (
      WidgetTester t,
    ) async {
      final Rig<StorySession> heb = _rig(_pack(course: 'heb', dialogic: false));
      await heb.pump(t);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      await heb.done(t);
      final Rig<StorySession> eng = _rig(_pack(dialogic: false));
      await eng.pump(t);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      await eng.done(t);
    });
  });

  group('a dialogic story', () {
    testWidgets(
      'stops after the page, asks, takes the choice, says the recast and goes on to the last page',
      (WidgetTester t) async {
        final Rig<StorySession> r = _rig(_pack());
        await r.pump(t);
        await t.tap(find.byKey(const Key('story-turn')));
        await r.wait(t, 100);
        expect(r.session.page, 1);
        expect(r.session.asking, isFalse);
        // the arrow of the page of the pause asks instead of turning
        await t.tap(find.byKey(const Key('story-turn')));
        await r.wait(t, 100);
        expect(r.session.asking, isTrue);
        expect(r.session.page, 1);
        expect(r.controller.voice, 'vo:eng.bounce.q');
        expect(find.byKey(const Key('story-turn')), findsNothing);
        expect(r.tile('o1'), findsOneWidget);
        // the right choice: a picture with a clip says its word as it is chosen; one attempt is written
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.heard.calls.last, 'now vo:eng.w.duck');
        expect(r.written, <String>['correct:o1']);
        expect(r.controller.voice, 'vo:eng.bounce.right', reason: 'the recast is the item\'s own right line');
        // after the praise the story goes on: page 3 is told, and the child turns to the end
        await r.wait(t, 1700);
        expect(r.session.asking, isFalse);
        expect(r.session.page, 2);
        expect(r.heard.calls.last, 'after vo:eng.st.p3 vo:eng.st.p3b');
        for (int i = 0; i < 2; i++) {
          await t.tap(find.byKey(const Key('story-turn')));
          await r.wait(t, 100);
        }
        expect(r.session.page, 4);
        expect(r.controller.finished, isFalse);
        await t.tap(find.byKey(const Key('story-turn')));
        await r.wait(t, 100);
        expect(r.controller.finished, isTrue);
        expect(r.attempts, hasLength(1), reason: 'the story itself writes nothing more');
        await r.done(t);
      },
    );

    testWidgets(
      'a wrong choice is a tagged mistake with the first hint: the page that answers it is told again',
      (WidgetTester t) async {
        final Rig<StorySession> r = _rig(_pack());
        await r.pump(t);
        await t.tap(find.byKey(const Key('story-turn')));
        await t.tap(find.byKey(const Key('story-turn')));
        await r.wait(t, 100);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(r.attempts.single.result, 'incorrect');
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        expect(r.session.chosenState.name, 'notYet');
        r.heard.clear();
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 1);
        expect(
          r.heard.calls,
          contains('after vo:eng.st.p2'),
          reason: 'the answering page (index 1) is told again',
        );
        expect(r.session.chosenId, isNull, reason: 'the child may try again');
        await r.done(t);
      },
    );

    testWidgets(
      'level 2 lays the pages so far in a row and plays them one after the other; level 3 lights the answer',
      (WidgetTester t) async {
        final Rig<StorySession> r = _rig(_pack());
        await r.pump(t);
        await t.tap(find.byKey(const Key('story-turn')));
        await t.tap(find.byKey(const Key('story-turn')));
        await r.wait(t, 100);
        await t.tap(r.tile('o2'));
        await r.wait(t, 1300);
        await t.tap(r.tile('o3'));
        await r.wait(t, 200);
        r.heard.clear();
        await r.wait(t, 1500);
        expect(r.controller.hintShown, 2);
        expect(r.session.showRow, isTrue);
        expect(find.byKey(const Key('story-row')), findsOneWidget);
        await r.wait(t, 2500);
        // pages 1 and 2 (indexes 0 and 1), in order, each with its own narration
        expect(r.heard.clips.where((String c) => c.startsWith('vo:eng.st.')).toList(), <String>[
          'vo:eng.st.p1',
          'vo:eng.st.p2',
        ]);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1500);
        expect(r.controller.hintShown, 3);
        expect(r.controller.guided, isTrue);
        expect(r.controller.answerShown, isTrue);
        // only the right choice is taken now
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(
          r.attempts.where((AttemptRecord a) => a.result == 'incorrect'),
          hasLength(3),
          reason: 'a guided item takes no more wrong answers',
        );
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        expect(r.attempts.last.hintLevel, 3);
        await r.done(t);
      },
    );

    testWidgets('the replay button at the question says the question again', (WidgetTester t) async {
      final Rig<StorySession> r = _rig(_pack());
      await r.pump(t);
      await t.tap(find.byKey(const Key('story-turn')));
      await t.tap(find.byKey(const Key('story-turn')));
      await r.wait(t, 100);
      final int nonce = r.controller.voiceNonce;
      await t.tap(find.byKey(const Key('lesson-replay')));
      await r.wait(t, 100);
      expect(r.controller.voiceNonce, greaterThan(nonce));
      expect(r.controller.voice, 'vo:eng.bounce.q');
      expect(r.controller.voiceReplaces, isTrue);
      await r.done(t);
    });
  });

  test('the new story files have no timer, countdown or streak (the child space has none)', () {
    final RegExp banned = RegExp('timer|countdown|streak|stopwatch', caseSensitive: false);
    for (final String f in <String>[
      'lib/play/story_session.dart',
      'lib/play/choice_session.dart',
      'lib/play/choice_row.dart',
    ]) {
      for (final String line in File(f).readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        expect(banned.hasMatch(line), isFalse, reason: '$f: $line');
      }
    }
  });
}
