import 'dart:async';

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'say_step.dart';
import 'template_session.dart';

/// LS09 say it with me (docs/languages/frame.md section 2.3): a picture and a word. The voice says the word, there is a pause for
/// the child, and the voice says it again. The child may say it: with a parent's voice switch for this language on and its model on
/// the phone there is a microphone (a [SayStepController]; the per-word matcher answers confident or unsure, never wrong);
/// otherwise there is an "I said it" button, which is practice only. Then a tap on the picture goes on, and counts as a listening
/// answer when the author scored it.
///
/// A step may be played picture first (docs/languages/band-a-build.md 2.6.1 R4): the question alone is asked, the microphone and "I said
/// it" are there from the start, and after the question and a pause the voice says the word, unless the child has already been heard. From
/// then on it is the echo step. A hearing screen (`answer.hear`, R3) is only heard: the line and the word once, no microphone, no "I said
/// it", the word again whenever the replay button is touched, and the picture once the word has been said.
///
/// Nothing here can be failed, and nothing is timed: the child is never asked to try again, and a missing or failing model only
/// means the step runs as echo, with no message.
class SayItSession extends TemplateSession {
  SayItSession(super.controller, this.activity, {this.say}) {
    say?.addListener(notify);
    if (activity.hear) {
      _showAfterTheWord();
    } else {
      _sayAgainLater();
    }
  }

  final SayItActivity activity;

  /// The microphone side, or null when the step runs as echo.
  final SayStepController? say;

  /// How long the child has to say the word before the voice says it again.
  static const Duration listenPause = Duration(milliseconds: 3200);

  /// The longest a hearing screen keeps its picture back for the word to end: a voice that never finishes must not hold the child.
  static const Duration wordWait = Duration(seconds: 8);

  /// How long a hearing screen stays after the tap before the next step: there is no praise to wait for.
  static const Duration hearPause = Duration(milliseconds: 400);

  bool _practiced = false;
  bool _done = false;
  int _round = 0;
  bool _wordSaid = false;

  /// The picture is on the stage: always, except on a hearing screen until its word has been said.
  bool get pictureShown => !activity.hear || _wordSaid;

  /// The microphone is offered: there is a step, and it has not given up.
  bool get hasMic => say != null && say!.state != SayState.unavailable;

  /// The picture may be tapped: the child has said the word (heard or not), or tapped "I said it"; on a hearing screen, once the word
  /// has been said.
  bool get canGoOn =>
      !_done &&
      (activity.hear
          ? _wordSaid
          : _practiced || say?.state == SayState.heard || say?.state == SayState.together);

  /// The child has already been given the word: heard (the praise says it) or helped (the voice said it with the child).
  bool get _gotTheWord => say?.state == SayState.heard || say?.state == SayState.together;

  void _sayAgainLater() {
    final int mine = ++_round;
    if (controller.pictureFirst) {
      _askThenSay(mine);
      return;
    }
    later(listenPause, () {
      // The voice says the word again unless the child has already gone on.
      if (mine == _round && !canGoOn && !_done) playClips?.call(<String>[activity.wordClip]);
    });
  }

  /// Picture first: the pause starts when the question has ended, and then the voice says the word (and its chip shows), unless the child
  /// was already heard or has gone on. "I said it" does not stop it: the child who tapped it has still not heard the word.
  void _askThenSay(int mine) {
    void afterQuestion() => later(listenPause, () {
      if (mine != _round || _done || _gotTheWord) return;
      playClips?.call(<String>[activity.wordClip]);
      controller.showWord();
    });
    // The voice and the lesson screen are given to the session just after it is made: look at them after that.
    later(Duration.zero, () {
      final Future<void> Function()? quiet = untilQuiet;
      if (quiet == null) {
        afterQuestion();
      } else {
        unawaited(quiet().then((_) => mine == _round && !disposed ? afterQuestion() : null));
      }
    });
  }

  /// A hearing screen: the line and the word are played by the lesson; the picture comes when they have ended (or after [wordWait]).
  void _showAfterTheWord() {
    void reveal() {
      if (_wordSaid) return;
      _wordSaid = true;
      notify();
    }

    later(Duration.zero, () {
      final Future<void> Function()? quiet = untilQuiet;
      if (quiet == null) {
        reveal();
      } else {
        unawaited(quiet().then((_) => reveal()));
      }
    });
    later(wordWait, reveal);
  }

  /// "I said it": practice only. Nothing is written.
  void saidIt() {
    if (_done || _practiced) return;
    _practiced = true;
    notify();
  }

  /// The tap on the picture.
  Future<void> goOn() async {
    if (!canGoOn) return;
    _done = true;
    notify();
    if (activity.hear) {
      controller.hearDone();
      later(hearPause, controller.next);
      return;
    }
    await controller.sayItDone();
    if (disposed) return;
    later(TemplateSession.praisePause, controller.next);
  }

  @override
  void onReset() {
    if (activity.hear) return; // a hearing screen is only heard: there is nothing to start again
    _practiced = false;
    _done = false;
    say?.stop();
    _sayAgainLater();
  }

  @override
  void onReplay() {
    playClips?.call(<String>[activity.wordClip], replace: true);
  }

  @override
  void onHint() => onReplay();

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final double side = (size.shortestSide * 0.82).clamp(80.0, 420.0);
      final bool ready = canGoOn;
      return Center(
        child: Semantics(
          button: ready,
          label: activity.altText,
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('say-picture'),
            behavior: HitTestBehavior.opaque,
            onTap: ready ? goOn : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: side,
              height: side,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: ready ? TokenColors.spark : TokenColors.cardLip,
                  width: ready ? 4 : 2,
                ),
              ),
              child: pictureShown ? PackSvg(activity.assets.svg(activity.picture)) : null,
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // The way on for every child: with the microphone or without it. It is never withdrawn.
        if (!activity.hear && !canGoOn && !_done)
          AnswerTile(
            key: const Key('say-done'),
            semanticLabel: He.sayDone.text,
            onPressed: saidIt,
            width: 168,
            child: Text(
              He.sayDone.text,
              textAlign: TextAlign.center,
              style: AppText.fixed(size: 28, weight: 600),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    say?.removeListener(notify);
    super.dispose();
  }
}
