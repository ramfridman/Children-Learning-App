// LS13, the placement game (docs/languages/frame.md section 3.2; L4): the placement document and its validator, the game built from
// it with the parent's questionnaire, the visit played through the lesson controller (probes without help, one neutral warm line, the
// staircase choosing each next probe), the placement replayed from the answers, and the skills below each entry handed to the engine.
// Fixture course, fake clips; no real content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/staircase.dart';
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/tap_answer_session.dart';
import 'package:nitznutz/world/language_placement.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/fakes.dart';
import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['cat', 'dog', 'duck'];

List<List<String>> _ladder(String s, int levels, int perLevel) => <List<String>>[
  for (int l = 0; l < levels; l++)
    <String>['${s}_${l}_1', for (int n = 2; n <= perLevel; n++) '${s}_${l}_$n'],
];

/// An English fixture course with a placement document: the oral strand `o` (4 levels of 4 probes; Band A) and the literacy strand
/// `l` (3 levels of 3 probes), offered only when the parent said the child knows some letters and the child is in Band B or C.
LangPack _pack({int perVisit = 8}) {
  final LangPack p = LangPack()..addPictures(_pictures);
  final List<List<String>> oral = _ladder('o', 4, 4);
  final List<List<String>> lit = _ladder('l', 3, 3);
  for (final String id in <String>[
    for (final List<String> l in oral) ...l,
    for (final List<String> l in lit) ...l,
  ]) {
    p.addProbe(id);
  }
  p.addPlacement(
    placementJson('eng', perVisit: perVisit, <Map<String, Object?>>[
      strandJson(
        'o',
        'eng',
        oral,
        assumes: <List<String>>[
          <String>['ENG-A-01'],
          <String>[],
          <String>[],
          <String>[],
        ],
        start: <Map<String, Object?>>[
          <String, Object?>{'answer': 'knowsLetters', 'equals': 'some', 'level': 1},
        ],
      ),
      strandJson(
        'l',
        'eng',
        lit,
        offer: <String, Object?>{'answer': 'knowsLetters', 'equals': 'some', 'minBand': 1},
      ),
    ]),
  );
  return p;
}

List<Map<String, Object?>> _strands(LangPack p) =>
    ((p.pack.docs['placement.eng.placement.json']! as Map<String, Object?>)['strands']! as List<Object?>)
        .cast<Map<String, Object?>>();

/// A visit on the lesson controller: the staircase is the flow.
class _Visit {
  _Visit(this.content, this.game) {
    flow = PlacementFlow(game, content.placement!);
    controller = LessonController(
      content: content,
      lesson: placementLessonFor(content, flow),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      flow: flow,
      record: (AttemptRecord r) async => attempts.add(r),
    );
  }

  final PackContent content;
  final PlacementGame game;
  late final PlacementFlow flow;
  late final LessonController controller;
  final List<AttemptRecord> attempts = <AttemptRecord>[];

  /// Answers the probe on screen right (`o1`) or wrong (`o2`) and goes on, as the session does after the pause.
  Future<void> answer(bool right) async {
    await controller.chooseOption(right ? 'o1' : 'o2');
    controller.next();
  }

  String get id => controller.current.id;
}

void main() {
  group('the document', () {
    test('a placement document passes the validator and reads as its model', () {
      final LangPack p = _pack();
      expect(_messages(p), isEmpty);
      expect(supportedTemplates.containsKey('tap_answer'), isTrue);
      expect(allSchemas.containsKey('placement'), isTrue);
      final PlacementDoc d = p.content.placement!;
      expect(d.id, 'eng.placement');
      expect(d.course, 'eng');
      expect(d.perVisit, 8);
      expect(d.strands.map((PlacementStrandDoc s) => s.id), <String>['o', 'l']);
      expect(d.strands[0].levels, hasLength(4));
      expect(d.strands[0].levels[0].assumes, <String>['ENG-A-01']);
      expect(d.strands[0].start.single.level, 1);
      expect(d.strands[1].offerAnswer, 'knowsLetters');
      expect(d.strands[1].offerMinBand, 1);
      expect(d.thanks.vo, 'vo:eng.placement.thanks');
    });

    test(
      'a probe is a probe: purpose probe, a tap or drum item, never voiced, never unscored, in one place',
      () {
        final LangPack a = _pack();
        a.activity('o_0_1')['purpose'] = 'learn';
        expect(_messages(a), contains(contains('"eng.o_0_1" must be a probe (purpose: probe)')));

        final LangPack b = _pack();
        b.activity('o_0_1')['voiceAnswer'] = true;
        expect(_messages(b), contains(contains('speech is never a probe')));

        final LangPack c = _pack();
        c.replace(
          'o_0_1',
          listenDoJson(
            id: 'o_0_1',
            mode: 'hotspots',
            purpose: 'probe',
            options: <Map<String, Object?>>[
              partOption('o1', at(0.1, 0.1, 0.3, 0.3)),
              partOption('o2', at(0.5, 0.5, 0.3, 0.3), tag: c.tag('lis.sem')),
            ],
            correct: 'o1',
          ),
        );
        expect(
          _messages(c),
          contains(contains('"eng.o_0_1" is a listen_do: a probe is a tap item or a drum item')),
        );

        final LangPack d = _pack();
        (_strands(d)[1]['levels']! as List<Object?>)[0] = <String, Object?>{
          'items': <String>['eng.o_0_1', 'eng.l_0_2'],
        };
        expect(_messages(d), contains(contains('"eng.o_0_1" is a probe of two places')));

        final LangPack e = _pack();
        ((_strands(e)[0]['levels']! as List<Object?>)[0]! as Map<String, Object?>)['items'] = <String>[
          'eng.nothing',
        ];
        expect(_messages(e), contains(contains('there is no activity "eng.nothing" in this pack')));
      },
    );

    test('a personal turn or a step the child does is never a probe, and a probe is not unscored', () {
      final LangPack p = _pack();
      p.replace(
        'o_0_1',
        storyJson(
          id: 'o_0_1',
          pages: <Map<String, Object?>>[
            storyPage('cat', <String>['vo:eng.st.a']),
            storyPage('dog', <String>['vo:eng.st.b']),
          ],
        ),
      );
      expect(_messages(p), contains(contains('"eng.o_0_1" is not scored, so it cannot be a probe')));
    });

    test('the rules of the ladders: a start inside the ladder, an offer that names both question and answer, skills in the pack', () {
      final LangPack a = _pack();
      ((_strands(a)[0]['start']! as List<Object?>)[0]! as Map<String, Object?>)['level'] = 6;
      expect(_messages(a), contains(contains('start[0].level: is not a level of the strand (0 to 3)')));

      final LangPack b = _pack();
      (_strands(b)[1]['offer']! as Map<String, Object?>).remove('equals');
      expect(
        _messages(b),
        contains(contains('names a questionnaire question and the answer that offers the strand')),
      );

      final LangPack c = _pack();
      (((_strands(c)[0]['levels']! as List<Object?>)[0]! as Map<String, Object?>)['assumes']!
              as List<Object?>)[0] =
          'ENG-A-09';
      expect(_messages(c), contains(contains('the skill ENG-A-09 is not in this pack')));
    });

    test('the manifest names it, the document is of its course, and a pack of the lands has none', () {
      final LangPack p = _pack();
      (p.pack.manifest['entries']! as Map<String, Object?>)['placements'] = <Object?>[];
      expect(_messages(p), contains(contains('entries.placements')));
      final LangPack q = _pack();
      (q.pack.docs['placement.eng.placement.json']! as Map<String, Object?>)['course'] = 'heb';
      expect(_messages(q), contains(contains('placement.eng.placement.json › course: must be eng')));
      final SamplePack core = SamplePack();
      core.addDocument(
        'placement.eng.placement.json',
        'placements',
        'eng.placement',
        _pack().pack.docs['placement.eng.placement.json']! as Map<String, Object?>,
      );
      expect(
        _run(core).map((Problem x) => '${x.path}: ${x.message}'),
        contains(contains('belongs to a language course')),
      );
    });

    test('the warm lines of the placement are Hebrew with niqqud, like every line the child hears', () {
      final LangPack p = _pack();
      (((p.pack.docs['placement.eng.placement.json']! as Map<String, Object?>)['thanks']!
              as Map<String, Object?>)['caption']!
          as List<Object?>)[0] = <String, Object?>{
        't': 'he',
        'v': 'תודה רבה',
      };
      expect(_messages(p), contains(contains('has no niqqud')));
    });
  });

  group('the game of a course', () {
    test('a course with no placement document has no game', () {
      expect(placementGameOf(LangPack().content), isNull);
    });

    test('the oral strand is always played; literacy only for a child whose parent said they know letters, in Band B or C', () {
      final PackContent c = _pack().content;
      expect(placementGameOf(c)!.strands.map((StrandPlan s) => s.id), <String>['o']);
      expect(
        placementGameOf(
          c,
          answers: const <String, String>{'knowsLetters': 'some'},
        )!.strands.map((StrandPlan s) => s.id),
        <String>['o'],
        reason: 'Band A is never offered literacy',
      );
      expect(
        placementGameOf(
          c,
          answers: const <String, String>{'knowsLetters': 'some'},
          presentationBand: 1,
        )!.strands.map((StrandPlan s) => s.id),
        <String>['o', 'l'],
      );
      expect(
        placementGameOf(
          c,
          answers: const <String, String>{'knowsLetters': 'no'},
          presentationBand: 2,
        )!.strands.map((StrandPlan s) => s.id),
        <String>['o'],
      );
    });

    test('a questionnaire answer sets where a staircase starts, and the staircase may still end lower', () {
      final PackContent c = _pack().content;
      expect(placementGameOf(c)!.stairs('o')!.level, 0);
      final PlacementGame g = placementGameOf(c, answers: const <String, String>{'knowsLetters': 'some'})!;
      expect(g.stairs('o')!.level, 1);
      expect(g.next(), 'eng.o_1_1');
      g.record('eng.o_1_1', right: false);
      expect(g.stairs('o')!.level, 0, reason: 'a miss goes down from where the answer started it');
    });
  });

  group('a visit on the lesson controller', () {
    test(
      'the probes come from the staircase, one after another; every probe is played without help',
      () async {
        final PackContent c = _pack().content;
        final _Visit v = _Visit(c, placementGameOf(c)!);
        expect(v.id, 'eng.o_0_1');
        expect(v.controller.noHelp, isTrue);
        await v.answer(true);
        expect(v.id, 'eng.o_0_2');
        await v.answer(true);
        expect(v.id, 'eng.o_1_1', reason: 'two right answers go up a level');
        await v.answer(false);
        expect(v.id, 'eng.o_0_3', reason: 'one wrong answer goes down');
        expect(v.attempts.map((AttemptRecord a) => a.result), <String>['correct', 'correct', 'incorrect']);
        expect(v.attempts.every((AttemptRecord a) => a.lessonId == placementIdFor('eng')), isTrue);
        expect(placementIdFor('eng'), 'placement-eng');
      },
    );

    test('no lamp and no show-me: a probe takes no hint and no "unsure"', () async {
      final PackContent c = _pack().content;
      final _Visit v = _Visit(c, placementGameOf(c)!);
      v.controller.showHint();
      await v.controller.unsure();
      expect(v.controller.hintShown, 0);
      expect(v.attempts, isEmpty);
    });

    test('the one warm line is the same whatever the answer, so no result can be read from it; no tag of a hint is shown', () async {
      final PackContent c = _pack().content;
      final _Visit right = _Visit(c, placementGameOf(c)!);
      await right.controller.chooseOption('o1');
      final PackContent c2 = _pack().content;
      final _Visit wrong = _Visit(c2, placementGameOf(c2)!);
      await wrong.controller.chooseOption('o2');
      expect(right.controller.voice, 'vo:eng.placement.thanks');
      expect(wrong.controller.voice, right.controller.voice);
      expect(wrong.controller.bubble, right.controller.bubble);
      expect(
        wrong.controller.feedback,
        right.controller.feedback,
        reason: 'the child is told nothing of the result',
      );
      expect(wrong.controller.errors, 0, reason: 'a wrong probe is not a mistake that brings help');
      expect(wrong.controller.guided, isFalse);
      expect(wrong.attempts.single.result, 'incorrect');
      expect(wrong.attempts.single.misconceptionTag, 'eng.lis.sem');
    });

    test(
      'a beginner who fails the first two probes ends the strand at once: two probes, not eight',
      () async {
        final PackContent c = _pack().content;
        final PlacementGame g = placementGameOf(c)!;
        final _Visit v = _Visit(c, g);
        await v.answer(false);
        await v.answer(false);
        expect(v.controller.finished, isTrue, reason: 'only the oral strand is offered, and it has stopped');
        expect(v.attempts, hasLength(2));
        expect(g.stairs('o')!.stopped, isTrue);
        expect(g.results['o']!.entry, 0);
        expect(
          v.controller.bubble,
          'הָיָה כֵּיף לְבַקֵּר!',
          reason: 'the visit ends with the placement\'s own line',
        );
      },
    );

    test(
      'a visit holds at most 8 probes, and the strand goes on in the next visit from the recorded answers',
      () async {
        final PackContent c = _pack().content;
        final PlacementGame g = placementGameOf(c)!;
        final _Visit v = _Visit(c, g);
        for (int i = 0; i < 8; i++) {
          expect(v.controller.finished, isFalse, reason: 'probe ${i + 1}');
          await v.answer(true);
        }
        expect(v.controller.finished, isTrue);
        expect(v.attempts, hasLength(8));
        expect(g.stairs('o')!.asked, 8);

        // the next visit: a new game from the pack, the recorded answers replayed into it
        final PlacementGame again = placementGameOf(c)!;
        final DateTime t0 = DateTime.utc(2026, 11, 3);
        replayPlacement(again, 'eng', <Attempt>[
          for (final (int i, AttemptRecord a) in v.attempts.indexed) _row(a, t0.add(Duration(minutes: i))),
        ]);
        expect(again.stairs('o')!.asked, 8);
        expect(again.stairs('o')!.stopped, isTrue);
        expect(
          again.results['o']!.entry,
          g.results['o']!.entry,
          reason: 'the placement is the same when replayed',
        );
        expect(again.complete, isTrue, reason: 'only the oral strand is offered: it has used its eight');
      },
    );

    test('the staircase of a strand is replayed from the answers of the placement lesson only', () {
      final PackContent c = _pack().content;
      final PlacementGame g = placementGameOf(c)!;
      final DateTime t0 = DateTime.utc(2026, 11, 3);
      replayPlacement(g, 'eng', <Attempt>[
        _row(_rec('eng.o_0_1', 'correct', 'placement-eng'), t0),
        _row(_rec('eng.o_0_2', 'correct', 'placement-eng'), t0.add(const Duration(minutes: 1))),
        // another lesson's answer, an answer of another course's placement, and an "unsure": none is part of the placement
        _row(_rec('eng.o_1_1', 'incorrect', 'some-lesson'), t0.add(const Duration(minutes: 2))),
        _row(_rec('eng.o_1_1', 'incorrect', 'placement-rus'), t0.add(const Duration(minutes: 3))),
        _row(_rec('eng.o_1_1', 'unsure', 'placement-eng'), t0.add(const Duration(minutes: 4))),
      ]);
      expect(g.stairs('o')!.asked, 2);
      expect(g.stairs('o')!.level, 1);
    });
  });

  group('what the child sees of a probe', () {
    for (final (String choice, String what) in <(String, String)>[
      ('o1', 'the right answer'),
      ('o2', 'a wrong answer'),
    ]) {
      testWidgets('$what: the tile is only chosen, and the screen is the same either way', (
        WidgetTester t,
      ) async {
        final LangPack p = LangPack()..addPictures(_pictures);
        p.addProbe('prb_1');
        final Rig<TapAnswerSession> r = Rig<TapAnswerSession>(
          p,
          'prb_1',
          (LessonController c, Activity a) => TapAnswerSession(c, a as TapAnswerActivity),
        );
        await r.pump(t);
        expect(r.controller.noHelp, isTrue);
        await t.tap(find.byKey(Key('option-$choice')));
        await r.wait(t, 100);
        expect(
          r.session.chosenState,
          AnswerState.selected,
          reason: 'never "correct" and never "not yet" for a probe',
        );
        expect(r.controller.feedback, FeedbackKind.correct);
        expect(
          r.controller.bubble,
          'נָכוֹן!',
          reason: 'one line for any answer (with a flow it is the placement thanks line)',
        );
        expect(r.attempts.single.result, choice == 'o1' ? 'correct' : 'incorrect');
        await r.wait(t, 1700);
        expect(r.controller.finished, isTrue);
        await r.done(t);
      });
    }
  });

  group('what the placement tells the engine', () {
    test('the skills below the entry point are assumed, and only for a strand that has stopped', () async {
      final PackContent c = _pack().content;
      final PlacementGame g = placementGameOf(c)!;
      expect(assumedSkills(c, g), isEmpty, reason: 'nothing has been asked');
      // climb: 8 right answers end the strand at level 3 or so; its entry is above the floor
      final _Visit v = _Visit(c, g);
      for (int i = 0; i < 8; i++) {
        await v.answer(true);
      }
      final StrandResult r = g.results['o']!;
      expect(r.stopped, isTrue);
      expect(r.entry, greaterThan(0));
      final Set<String> assumed = assumedSkills(c, g);
      expect(assumed, contains('ENG-A-01'), reason: 'the skill the floor level lists');
      expect(assumed, contains('ENG-A-02'), reason: 'the skill of the probes of the levels below the entry');
      final Engine engine = Engine(catalog: engineCatalog(c))..assume(assumed);
      expect(engine.skill('ENG-A-01').assumed, isTrue);
      expect(engine.skill('ENG-A-01').p, engine.params.priorAssumed);
    });

    test(
      'a strand that failed its floor assumes nothing, and one that has not stopped assumes nothing yet',
      () async {
        final PackContent c = _pack().content;
        final PlacementGame g = placementGameOf(c)!;
        final _Visit v = _Visit(c, g);
        await v.answer(false);
        expect(assumedSkills(c, g), isEmpty, reason: 'one miss does not stop it');
        await v.answer(false);
        expect(assumedSkills(c, g), isEmpty, reason: 'it stopped at the floor: nothing is below the entry');
      },
    );
  });
}

AttemptRecord _rec(String activityId, String result, String lessonId) => AttemptRecord(
  at: DateTime.utc(2026, 11, 3),
  profileId: 'p-1',
  packId: 'lang-eng',
  packVersion: '1.0.0',
  lessonId: lessonId,
  activityId: activityId,
  activityRevision: 1,
  template: 'tap_answer',
  templateVersion: '1.3',
  skillId: 'ENG-A-02',
  result: result,
  attemptNo: 1,
  hintLevel: 0,
  misconceptionTag: '',
  response: 'o1',
  durationMs: 100,
);

/// A database row as the replay reads it.
Attempt _row(AttemptRecord r, DateTime at) => Attempt(
  id: 0,
  profileId: r.profileId,
  packId: r.packId,
  packVersion: r.packVersion,
  lessonId: r.lessonId,
  activityId: r.activityId,
  activityRevision: r.activityRevision,
  template: r.template,
  templateVersion: r.templateVersion,
  skillId: r.skillId,
  result: r.result,
  attemptNo: r.attemptNo,
  hintLevel: r.hintLevel,
  misconceptionTag: r.misconceptionTag,
  response: r.response,
  durationMs: r.durationMs,
  at: at,
  sessionId: null,
  input: r.input,
);
