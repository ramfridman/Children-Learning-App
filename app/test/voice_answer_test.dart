import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/lexicon.dart';
import 'package:nitznutz/speech/voice_answer.dart';

import 'support/fake_speech.dart';

class Rig {
  Rig(List<Scripted> script, {Duration silence = const Duration(milliseconds: 1500)})
    : engine = FakeSpeechEngine(script) {
    controller = VoiceAnswerController(
      engine: engine,
      expected: () => <Expected>[
        Expected.number('o2', 2, correct: false),
        Expected.number('o3', 3, correct: true),
        Expected.number('o4', 4, correct: false),
      ],
      onAnswer: (String id) async => answers.add(id),
      silence: silence,
      beat: Duration.zero,
      beforeListen: () async => engine.log.add('voice stopped'),
      onPrompt: prompts.add,
      onIntent: intents.add,
      onOutcome: outcomes.add,
    );
    controller.addListener(() => states.add(controller.state));
  }

  final FakeSpeechEngine engine;
  late final VoiceAnswerController controller;
  final List<String> answers = <String>[];
  final List<VoicePrompt> prompts = <VoicePrompt>[];
  final List<Intent> intents = <Intent>[];
  final List<ListenOutcome> outcomes = <ListenOutcome>[];
  final List<MicState> states = <MicState>[];
}

void main() {
  test(
    'a clear right answer counts like a tap: the mic goes through its states and the answer is used once',
    () async {
      final Rig r = Rig(<Scripted>[Scripted.says('שלוש')]);
      await r.controller.tap();
      expect(r.answers, <String>['o3']);
      expect(r.outcomes, <ListenOutcome>[ListenOutcome.accepted]);
      expect(
        r.states,
        containsAllInOrder(<MicState>[
          MicState.listening,
          MicState.thinking,
          MicState.understood,
          MicState.ready,
        ]),
      );
      expect(r.controller.state, MicState.ready);
      expect(r.engine.micOpen, isFalse);
    },
  );

  test('the guide stops talking before the mic opens, and the mic opens only on a tap', () async {
    final Rig r = Rig(<Scripted>[Scripted.says('שלוש')]);
    expect(r.engine.listens, 0);
    await r.controller.tap();
    expect(r.engine.log, <String>['voice stopped', 'prepare', 'listen']);
  });

  test('the silence a child may take follows the band, and a listen never runs past its cap', () async {
    final Rig a = Rig(<Scripted>[Scripted.says('שלוש')], silence: const Duration(seconds: 2));
    await a.controller.tap();
    expect(a.engine.lastSilence, const Duration(seconds: 2));
    expect(a.engine.lastMax, const Duration(seconds: 8));
  });

  group('a wrong answer said aloud is checked, never counted on its own', () {
    test('"four" asks "did you say...?" and the tick takes it', () async {
      final Rig r = Rig(<Scripted>[Scripted.says('ארבע')]);
      await r.controller.tap();
      expect(r.answers, isEmpty);
      expect(r.controller.state, MicState.confirming);
      expect(r.controller.optionId, 'o4');
      expect(r.prompts, <VoicePrompt>[VoicePrompt.confirm]);
      await r.controller.confirmYes();
      expect(r.answers, <String>['o4']);
      expect(r.outcomes.last, ListenOutcome.confirmed);
    });

    test('or the child says "yes" after tapping the mic again', () async {
      final Rig r = Rig(<Scripted>[Scripted.says('ארבע'), Scripted.says('כן')]);
      await r.controller.tap();
      expect(r.controller.state, MicState.confirming);
      await r.controller.tap();
      expect(r.answers, <String>['o4']);
    });

    test('"no" or the again button takes it back, and the question stays open', () async {
      final Rig r = Rig(<Scripted>[Scripted.says('ארבע'), Scripted.says('לא')]);
      await r.controller.tap();
      await r.controller.tap();
      expect(r.answers, isEmpty);
      expect(r.controller.state, MicState.ready);
      expect(r.prompts.last, VoicePrompt.mixedUp);

      final Rig s = Rig(<Scripted>[Scripted.says('ארבע')]);
      await s.controller.tap();
      s.controller.confirmNo();
      expect(s.answers, isEmpty);
      expect(s.controller.state, MicState.ready);
    });
  });

  group('unclear speech is never wrong', () {
    test('the first time the guide asks again, the second time the cards invite a tap', () async {
      final Rig r = Rig(<Scripted>[Scripted.says('בננה'), Scripted.says('גלידה')]);
      await r.controller.tap();
      expect(r.controller.state, MicState.ready);
      expect(r.prompts, <VoicePrompt>[VoicePrompt.mixedUp]);
      await r.controller.tap();
      expect(r.controller.state, MicState.tapOnly);
      expect(r.prompts, <VoicePrompt>[VoicePrompt.mixedUp, VoicePrompt.tapInstead]);
      expect(r.controller.canListen, isFalse);
      expect(r.answers, isEmpty);
      // The mic has faded: touching it does nothing.
      await r.controller.tap();
      expect(r.engine.listens, 2);
    });

    test('silence counts the same way', () async {
      final Rig r = Rig(<Scripted>[Scripted.silence(), Scripted.silence()]);
      await r.controller.tap();
      await r.controller.tap();
      expect(r.controller.state, MicState.tapOnly);
      expect(r.outcomes, <ListenOutcome>[ListenOutcome.silent, ListenOutcome.silent]);
      expect(r.answers, isEmpty);
    });

    test('a new question offers voice again', () async {
      final Rig r = Rig(<Scripted>[Scripted.silence(), Scripted.silence(), Scripted.says('שלוש')]);
      await r.controller.tap();
      await r.controller.tap();
      expect(r.controller.state, MicState.tapOnly);
      r.controller.reset();
      expect(r.controller.state, MicState.ready);
      await r.controller.tap();
      expect(r.answers, <String>['o3']);
    });

    test('whatever is said, nothing but a clear right answer or a confirmed one is ever given', () async {
      final math.Random random = math.Random(11);
      const List<String> pool = <String>[
        'שלוש',
        'ארבע',
        'שתיים',
        'חמש',
        'בננה',
        '',
        'לא',
        'כן',
        'לא שלוש',
        'עוד פעם',
        'אה',
        'שלוס',
        'ארבעה',
        'מה',
      ];
      for (int round = 0; round < 300; round++) {
        final List<Scripted> script = <Scripted>[
          for (int i = 0; i < 6; i++)
            Scripted.says(pool[random.nextInt(pool.length)], confidence: random.nextDouble()),
        ];
        final Rig r = Rig(script);
        for (int i = 0; i < 6; i++) {
          if (r.controller.state == MicState.confirming && random.nextBool()) {
            r.controller.confirmNo();
          } else {
            await r.controller.tap();
          }
        }
        for (final String a in r.answers) {
          // A wrong option only ever arrives through the confirm step.
          if (a != 'o3') expect(r.outcomes, contains(ListenOutcome.confirmed), reason: 'round $round: $a');
        }
      }
    });
  });

  test('"again", "help" and "stop" are passed on and are not answers', () async {
    final Rig r = Rig(<Scripted>[Scripted.says('עוד פעם'), Scripted.says('לא יודע'), Scripted.says('די')]);
    await r.controller.tap();
    await r.controller.tap();
    await r.controller.tap();
    expect(r.intents, <Intent>[Intent.repeat, Intent.help, Intent.stop]);
    expect(r.answers, isEmpty);
    expect(r.controller.state, MicState.ready);
  });

  test('a clear single word is taken without waiting for the end of the silence', () async {
    final Rig r = Rig(<Scripted>[Scripted.settles('שלוש')]);
    await r.controller.tap();
    expect(r.answers, <String>['o3']);
    expect(r.engine.cancels, greaterThan(0));
    expect(r.engine.micOpen, isFalse);
  });

  test('a settled wrong word is not taken early either', () async {
    final Rig r = Rig(<Scripted>[Scripted.settles('ארבע'), Scripted.silence()]);
    unawaited(r.controller.tap());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(r.answers, isEmpty);
    r.controller.stop();
    expect(r.engine.micOpen, isFalse);
  });

  test('a microphone or model that fails leaves the cards to tap, and nothing breaks', () async {
    final Rig a = Rig(<Scripted>[Scripted.fails()]);
    await a.controller.tap();
    expect(a.controller.state, MicState.tapOnly);
    expect(a.outcomes, <ListenOutcome>[ListenOutcome.failed]);

    final Rig b = Rig(<Scripted>[]);
    b.engine.failPrepare = true;
    await b.controller.tap();
    expect(b.controller.state, MicState.tapOnly);
    expect(b.engine.listens, 0);
  });

  test('leaving the question stops the listen and closes the microphone', () async {
    final Rig r = Rig(<Scripted>[Scripted.hangs()]);
    unawaited(r.controller.tap());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(r.engine.micOpen, isTrue);
    r.controller.stop();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(r.engine.micOpen, isFalse);
    expect(r.answers, isEmpty);
    expect(r.controller.state, MicState.ready);
    r.controller.dispose();
  });

  test('the outcomes are fixed words, never text', () {
    for (final ListenOutcome o in ListenOutcome.values) {
      expect(o.name, matches(RegExp(r'^[a-z]+$')));
    }
  });
}
