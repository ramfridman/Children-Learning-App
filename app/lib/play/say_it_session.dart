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
/// Nothing here can be failed, and nothing is timed: the child is never asked to try again, and a missing or failing model only
/// means the step runs as echo, with no message.
class SayItSession extends TemplateSession {
  SayItSession(super.controller, this.activity, {this.say}) {
    say?.addListener(notify);
    _sayAgainLater();
  }

  final SayItActivity activity;

  /// The microphone side, or null when the step runs as echo.
  final SayStepController? say;

  /// How long the child has to say the word before the voice says it again.
  static const Duration pause = Duration(milliseconds: 3200);

  bool _practiced = false;
  bool _done = false;
  int _round = 0;

  /// The microphone is offered: there is a step, and it has not given up.
  bool get hasMic => say != null && say!.state != SayState.unavailable;

  /// The picture may be tapped: the child has said the word (heard or not), or tapped "I said it".
  bool get canGoOn =>
      !_done && (_practiced || say?.state == SayState.heard || say?.state == SayState.together);

  void _sayAgainLater() {
    final int mine = ++_round;
    later(pause, () {
      // The voice says the word again unless the child has already gone on.
      if (mine == _round && !canGoOn && !_done) playClips?.call(<String>[activity.wordClip]);
    });
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
    await controller.sayItDone();
    if (disposed) return;
    later(TemplateSession.praisePause, controller.next);
  }

  @override
  void onReset() {
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
              child: PackSvg(activity.assets.svg(activity.picture)),
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
        if (!canGoOn && !_done)
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
