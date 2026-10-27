import 'dart:async';

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import '../speech/answer_matcher.dart';
import '../speech/lexicon.dart';
import '../speech/speech_engine.dart';
import '../speech/voice_answer.dart';
import '../strings/he.dart';
import 'lesson_controller.dart';
import 'template_session.dart';

/// Joins the voice of one lesson to its screen: it owns the [VoiceAnswerController], tells it which answers the
/// activity on screen expects, turns a spoken answer into the same call as a tap, speaks the guide's few listening
/// lines, lights the card that was understood, and keeps the record of how each listen went.
class LessonVoice {
  LessonVoice({
    required SpeechEngine engine,
    required this.lesson,
    required this.session,
    required this.silence,
    required this.stopGuide,
    required this.record,
    required this.onHome,
    this.onWords,
    Duration beat = const Duration(milliseconds: 700),
  }) {
    answer = VoiceAnswerController(
      engine: engine,
      expected: () => session()?.voiceExpected() ?? const <Expected>[],
      onAnswer: (String id) async => session()?.chooseByVoice(id),
      silence: silence,
      beat: beat,
      beforeListen: stopGuide,
      onPrompt: _prompt,
      onIntent: _intent,
      onOutcome: (ListenOutcome o) => record(session()?.voiceAnswerType ?? 'word', o.name),
      onWords: onWords,
    )..addListener(_light);
  }

  final LessonController lesson;

  /// What the recogniser heard for one answer, for the parent's word alerts (not stored by the lesson).
  final void Function(List<String> texts)? onWords;

  /// The activity on screen now.
  final TemplateSession? Function() session;
  final Duration silence;
  final Future<void> Function() stopGuide;

  /// Keeps one listen: the kind of answer and how it went, as fixed words.
  final void Function(String answerType, String outcome) record;
  final VoidCallback onHome;
  late final VoiceAnswerController answer;

  Spoken _line(String vo, String caption) => Spoken(vo: vo, caption: caption);

  void _prompt(VoicePrompt p) {
    switch (p) {
      case VoicePrompt.mixedUp:
        lesson.speak(_line('vo:core.listen.mixed', He.listenMixed.text));
      case VoicePrompt.confirm:
        lesson.speak(_line('vo:core.listen.confirm', He.listenConfirm.text));
      case VoicePrompt.tapInstead:
        lesson.speak(_line('vo:core.listen.tap', He.listenTap.text));
        session()?.inviteTap();
    }
  }

  void _intent(Intent i) {
    switch (i) {
      case Intent.repeat:
        lesson.replayPrompt();
      case Intent.help:
        // "I don't know" is welcomed and opens the same path as the eye button.
        unawaited(lesson.unsure());
      case Intent.stop:
        onHome();
      case Intent.yes || Intent.no:
        break;
    }
  }

  /// The card that was understood or half heard glows, as a hint does.
  void _light() {
    final MicState s = answer.state;
    if (s == MicState.confirming || s == MicState.understood) {
      session()?.setVoiceLit(answer.optionId);
    } else if (s != MicState.tapOnly) {
      session()?.setVoiceLit(null);
    }
  }

  /// A new question: the mic is offered again.
  void newQuestion() => answer.reset();

  /// The guide is about to speak, or the child leaves: stop listening.
  void hush() => answer.stop();

  void dispose() {
    answer.removeListener(_light);
    answer.dispose();
  }
}
