import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'choice_row.dart' show rowDirectionOf, withTallStage;
import 'lesson_controller.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The sound-boxes template in drum mode (LS03, docs/languages/frame.md section 2.3): the word is heard with its picture, and the child
/// taps a drum once for each part of it; a tap makes a beat sound and lights a dot (the count is the child's own, shown as dots and
/// never as a number), and the check mark says "that's all". It is a free response: a count of `beats` is right; one more and one
/// fewer are mapped to the course's tags (`one_more`, `one_fewer`; the Hebrew and Russian courses give them the same tag); any other
/// count is a retry with no tag. The response is the count, `n=3`.
///
/// The hints: level 1 says the word slowly, with a pause between the beats; level 2 claps one pair of hands for each beat while each
/// beat lights (the beats as movement and light: a new representation); level 3 drums the word for the child, and then only the right
/// count is taken. Nothing is red, and a count that is not the word's goes back to nothing, ready for another try.
class SoundBoxesSession extends TemplateSession {
  SoundBoxesSession(super.controller, this.drum) {
    // The word is heard after the instruction, with its picture on the stage.
    later(Duration.zero, () => playClips?.call(drum.word, replace: false));
  }

  final SoundBoxesActivity drum;

  /// Most taps the drum takes: a child who hammers it is not counted past this, and the count is then simply wrong.
  static const int mostTaps = 9;

  /// The taps so far (the dots that are lit), the drum's lit moment, and the hands that clap at level 2.
  int taps = 0;
  bool struck = false;
  int hands = 0;
  bool demoRunning = false;
  AnswerState state = AnswerState.idle;
  bool _busy = false;

  /// The child taps the drum: a beat sounds and a dot lights.
  void tap() {
    if (_busy || demoRunning || state == AnswerState.correct) return;
    if (taps >= mostTaps) return;
    taps++;
    _strike();
    notify();
  }

  void _strike() {
    struck = true;
    final String? sound = drum.drumClip;
    if (sound != null) playClips?.call(<String>[sound], replace: true);
    later(const Duration(milliseconds: 220), () {
      struck = false;
      notify();
    });
  }

  /// "That's all": the count is the answer. A count that is not the word's goes back to nothing for another try, and no count is
  /// taken at all once the help is at its top and the count is not the word's (the child drums it again).
  Future<void> done() async {
    if (_busy || demoRunning || taps == 0 || state == AnswerState.correct) return;
    if (controller.guided && taps != drum.beats) {
      taps = 0;
      notify();
      return;
    }
    _busy = true;
    final Outcome o = await controller.submitPlacement(
      right: taps == drum.beats,
      tag: taps == drum.beats ? '' : drum.tagFor(taps),
      response: ResponseCode.count(taps),
    );
    if (disposed) return;
    if (o.correct || o.settled) {
      // A probe of the placement game ends on its one answer, right or not, and shows nothing "not yet".
      state = o.settled ? AnswerState.selected : AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      state = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        state = AnswerState.idle;
        taps = 0;
        _busy = false;
        notify();
      });
    }
  }

  // ---- hints ----

  @override
  void onReset() {
    taps = 0;
    hands = 0;
    struck = false;
    demoRunning = false;
    state = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    playClips?.call(drum.word, replace: false);
  }

  @override
  void onHint() {
    switch (hintPictureOf(drum)) {
      case HintPicture.slowBeats:
        playClips?.call(drum.slow.isEmpty ? drum.word : drum.slow, replace: false);
      case HintPicture.clapEach:
        _clap();
      default:
        _drumItForTheChild();
    }
  }

  /// One pair of hands claps for each beat, the beat lit: the beats as movement and light.
  void _clap() {
    hands = 0;
    for (int i = 1; i <= drum.beats; i++) {
      later(Duration(milliseconds: 700 * i), () {
        hands = i;
        _strike();
        notify();
      });
    }
  }

  /// The friend drums the word: a dot lights for each beat; then the dots clear, and the child drums it after.
  void _drumItForTheChild() {
    demoRunning = true;
    taps = 0;
    hands = 0;
    notify();
    for (int i = 1; i <= drum.beats; i++) {
      later(Duration(milliseconds: 800 * i), () {
        taps = i;
        _strike();
        notify();
      });
    }
    later(Duration(milliseconds: 800 * drum.beats + 900), () {
      demoRunning = false;
      taps = 0;
      notify();
      controller.demoDone();
    });
  }

  // ---- layout ----

  @override
  ActivitySpec layoutFor(ActivitySpec base) => withTallStage(base);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _DrumStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;
}

class _DrumStage extends StatelessWidget {
  const _DrumStage(this.s, this.size);

  final SoundBoxesSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final SoundBoxesActivity a = s.drum;
    final TextDirection dir = rowDirectionOf(a.course, TextDirection.rtl);
    final double touch = AppLayout.of(context).touch.minControl;
    final double picture = math.min(size.height * 0.4, size.width * 0.4);
    final double dots = math.min(36, (size.width - 24) / (SoundBoxesSession.mostTaps * 1.4));
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('drum-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            // The word's picture, at the start corner; the drum in the middle of what is left.
            Positioned(
              left: 8,
              top: 8,
              width: picture,
              height: picture,
              child: PackSvg(a.assets.svg(a.picture), key: const Key('drum-picture')),
            ),
            Positioned(
              left: picture * 0.5,
              right: 0,
              top: 0,
              bottom: dots + 24,
              child: Center(child: _drum(math.min(size.height * 0.5, size.width * 0.42))),
            ),
            // The hands of the second hint clap above the dots, one pair for each beat so far.
            if (s.hands > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: dots + 18,
                child: Directionality(
                  textDirection: dir,
                  child: Row(
                    key: const Key('drum-hands'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < s.hands; i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.back_hand_rounded, size: 30, color: TokenColors.correctGlow),
                        ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Directionality(
                textDirection: dir,
                child: Row(
                  key: const Key('drum-dots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < s.taps; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                          key: Key('drum-dot-$i'),
                          width: dots,
                          height: dots,
                          decoration: const BoxDecoration(
                            color: TokenColors.correctGlow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // "That's all": the check mark, at the end corner in the course's direction.
            Positioned(
              left: dir == TextDirection.rtl ? 12 : null,
              right: dir == TextDirection.rtl ? null : 12,
              bottom: 12,
              child: PebbleButton(
                key: const Key('drum-done'),
                semanticLabel: He.drumDoneSemantics.text,
                size: math.max(72, touch),
                onPressed: s.taps == 0 ? null : s.done,
                child: const Icon(Icons.check_rounded, size: 40, color: TokenColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The drum: a round skin on a rim, which lights for a moment at each beat. The whole disc is the target.
  Widget _drum(double side) {
    final bool lit = s.struck;
    final bool notYet = s.state == AnswerState.notYet;
    return Semantics(
      button: true,
      label: He.drumSemantics.text,
      child: GestureDetector(
        key: const Key('drum'),
        behavior: HitTestBehavior.opaque,
        onTap: s.tap,
        child: AnimatedScale(
          scale: lit ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lit ? TokenColors.sparkTint : TokenColors.skyTint,
              border: Border.all(color: notYet ? TokenColors.notYetRing : TokenColors.ink, width: 8),
              boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
            ),
            child: Center(
              child: Container(
                width: side * 0.62,
                height: side * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: TokenColors.hairline, width: 4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
