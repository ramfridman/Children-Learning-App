// QA's defects of milestone L3 (docs/qa/l3-languages-verification.md): QA-L3-1 to QA-L3-5, each the proof of a defect that is now
// fixed, so each runs in every build.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/harness.dart';
import 'support/language_screens.dart' show langKid;
import 'support/qa_l3_say.dart';

Finder get _mic => find.byKey(const Key('lesson-mic'));

void main() {
  setUpAll(loadAppFonts);

  // QA-L3-1: nothing in the app asks the release gate. docs/milestones/L3.md section 4 and 8.3: "Until a language passes, its say-it
  // runs in echo mode". No language has passed (the gate needs bands A, B and C), so with the voice switch on and a model on the
  // phone the step must still be echo until a build says that language passed.
  testWidgets(
    'QA-L3-1: a language whose release gate has not passed runs its say-it in echo mode, switch on and model there',
    (WidgetTester t) async {
      final AppRig rig = await qaOpenSay(t, voice: true, installed: true, released: false);
      expect(
        _mic,
        findsNothing,
        reason: 'no language has passed the release gate, so no microphone is offered',
      );
      expect(
        find.byKey(const Key('say-done')),
        findsOneWidget,
        reason: 'the "I said it" button is the way on',
      );
      expect(<int>[rig.speech.prepares, rig.speech.listens], <int>[0, 0]);
    },
  );

  // QA-L3-2: the microphone must close when the app leaves the screen. The Hebrew voice path hushes on pause, inactive and hidden;
  // the say step does not.
  testWidgets(
    'QA-L3-2: the microphone closes at once when the app goes to the background in the middle of a listen',
    (WidgetTester t) async {
      final AppRig rig = await qaOpenSay(t, script: <Scripted>[Scripted.hangs()]);
      await t.tap(_mic);
      await qaWait(t, 800);
      expect(rig.speech.micOpen, isTrue, reason: 'the listen is under way (the fake never ends it)');
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await qaWait(t, 300);
      expect(rig.speech.micOpen, isFalse, reason: 'the app is not on screen: the microphone must be closed');
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await qaWait(t, 1500);
      expect(
        await rig.db.attemptsOf(langKid),
        isEmpty,
        reason: 'what a listen in the background heard is never applied',
      );
      expect(rig.speech.listens, 1);
    },
  );

  // QA-L3-3: a spoken success that the cap or the strand refuses must change nothing at all (Engine._speechCounts says so), but
  // apply() goes on to _updateGaps, which counts it toward repairing a gap, and to the representation statistics.
  group('QA-L3-3: refused speech is no evidence anywhere', () {
    Engine engineWith({required bool speaking}) => Engine(
      catalog: Catalog(
        skills: <SkillNode>[SkillNode(id: 'ENG-A-12', course: 'eng', speaking: speaking)],
        items: <ItemMeta>[
          ItemMeta(
            id: 'eng.a',
            course: 'eng',
            skills: <String, double>{'ENG-A-12': 1},
            purpose: Purpose.learn,
            checkType: CheckType.practice,
            representation: Representation.embodied,
            variantGroup: 'a',
            difficulty: 0.2,
            optionCount: 0,
            tags: const <String>{},
            revision: 1,
          ),
        ],
      ),
    );

    int n = 0;
    AttemptEvent event({bool speech = false}) => AttemptEvent(
      id: ++n,
      at: DateTime.utc(2026, 11, 5, 9, n),
      activityId: 'eng.a',
      result: Result.correct,
      course: 'eng',
      viaSpeech: speech,
    );

    test('speech over the cap does not repair a gap', () {
      final Engine e = engineWith(speaking: true);
      e.apply(event()); // one tap success
      e.apply(event(speech: true)); // speech 1 of 1 others: at the cap
      final Gap gap = Gap(
        origin: 'ENG-A-12',
        skill: 'ENG-A-12',
        foundAt: DateTime.utc(2026, 11, 5, 8),
        probes: 0,
        via: 'walk',
      );
      e.state.gaps.add(gap);
      for (int i = 0; i < 10; i++) {
        e.apply(event(speech: true)); // all refused by the cap
      }
      expect(gap.repairSuccesses, 0, reason: 'ten refused spoken answers repaired nothing');
      expect(gap.repaired, isFalse);
    });

    test('speech for a skill that is not a speaking skill adds nothing to the representation statistics', () {
      final Engine e = engineWith(speaking: false);
      e.apply(event(speech: true));
      final RepStats r = e.state.repStats('ENG-A', Representation.embodied);
      expect(<int>[r.tries, r.successes], <int>[0, 0]);
    });
  });

  // QA-L3-4: the lamp is on screen in a say-it step and does nothing.
  testWidgets('QA-L3-4: the lamp of a say-it step does something (the word is said again) or is not there', (
    WidgetTester t,
  ) async {
    final AppRig rig = await qaOpenSay(t, voice: false);
    await qaWait(t, 1500); // the voice's own second saying of the word (after its pause) is over
    final int before = rig.player.played.length;
    final Finder lamp = find.byKey(const Key('lesson-hint'));
    if (lamp.evaluate().isNotEmpty) {
      await t.tap(lamp);
      await qaWait(t, 800);
      expect(rig.player.played.length, greaterThan(before), reason: 'a lamp that is shown must answer a tap');
    }
  });

  // QA-L3-5: tool/say_eval.dart with --sweep reads every recording at the boosts 3, 5, 8, 12 and 16 and takes `boosts.first` (3) as
  // "the result", while its first line says "mode: biased (boost 8.0)". Evidence: the run of 2026-11-06 on 340 Speech Commands clips
  // printed 83.1% heard for the headline and 85.6% in the sweep row of boost 8 at the same accept (the 85.6% is the figure of L3.md).
  test('QA-L3-5: the headline result and the csv of a say_eval sweep are those of the boost the model is pinned to', () {
    final String src = File('tool/say_eval.dart').readAsStringSync();
    expect(
      src.contains('tallyOf(boosts.first'),
      isFalse,
      reason: 'the headline of a sweep must use spec.hotwordBoost, not the first (lowest) boost of the sweep',
    );
  });
}
