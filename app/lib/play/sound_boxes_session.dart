import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/board.dart' show BoardClass;
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
    // A count off by two or more is a retry with no tag and no evidence (docs/languages/frame.md section 2.3): nothing is written and no
    // help is escalated; the dots clear for another try. A probe has one answer, so it is written like any other (QA-L4-6).
    if ((taps - drum.beats).abs() >= 2 && drum.purpose != 'probe') {
      _busy = true;
      state = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        state = AnswerState.idle;
        taps = 0;
        _busy = false;
        notify();
      });
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

/// The zones of the drum's stage on one board, in the stage's points, for a course that reads left to right; Hebrew mirrors every x
/// (docs/design/languages-l4-layout.md section 5). The word's picture is at the start corner, the drum next to it, the hands and the dots
/// in a band that stops before the check mark, and the check mark alone at the end corner, below the drum.
class _Zones {
  const _Zones({
    required this.width,
    required this.inset,
    required this.picture,
    required this.drum,
    required this.handsY,
    required this.handsH,
    required this.dotsY,
    required this.dot,
    required this.gap,
    required this.check,
    required this.band,
  });

  final double width;

  /// How far the stage's room lies inside the stage on a tablet (its card has a 16 point rim).
  final double inset;
  final Rect picture;
  final Rect drum;
  final double handsY;
  final double handsH;
  final double dotsY;
  final double dot;
  final double gap;
  final Rect check;
  final (double, double) band;

  static _Zones of(BoardClass b) => switch (b) {
    BoardClass.phone => const _Zones(
      width: 330,
      inset: 0,
      picture: Rect.fromLTWH(8, 8, 96, 96),
      drum: Rect.fromLTWH(159, 8, 116, 116),
      handsY: 132,
      handsH: 34,
      dotsY: 182,
      dot: 18,
      gap: 8,
      check: Rect.fromLTWH(246, 169, 72, 72),
      band: (8, 234),
    ),
    BoardClass.phoneSE => const _Zones(
      width: 270,
      inset: 0,
      picture: Rect.fromLTWH(8, 8, 80, 80),
      drum: Rect.fromLTWH(129, 8, 100, 100),
      handsY: 116,
      handsH: 30,
      dotsY: 158,
      dot: 14,
      gap: 4,
      check: Rect.fromLTWH(186, 161, 72, 72),
      band: (8, 174),
    ),
    BoardClass.tabletLandscape => const _Zones(
      width: 584,
      inset: 16,
      picture: Rect.fromLTWH(12, 12, 150, 150),
      drum: Rect.fromLTWH(253, 16, 240, 240),
      handsY: 280,
      handsH: 44,
      dotsY: 350,
      dot: 32,
      gap: 12,
      check: Rect.fromLTWH(476, 438, 96, 96),
      band: (12, 464),
    ),
    BoardClass.tabletPortrait => const _Zones(
      width: 772,
      inset: 16,
      picture: Rect.fromLTWH(12, 12, 180, 180),
      drum: Rect.fromLTWH(332, 16, 300, 300),
      handsY: 340,
      handsH: 50,
      dotsY: 420,
      dot: 36,
      gap: 12,
      check: Rect.fromLTWH(664, 656, 96, 96),
      band: (12, 652),
    ),
  };

  /// [r] as the course reads: its x mirrored for a right-to-left course, and moved into the room the stage really has.
  Rect at(Rect r, bool rtl) =>
      Rect.fromLTWH((rtl ? width - r.left - r.width : r.left) - inset, r.top - inset, r.width, r.height);

  (double, double) bandAt(bool rtl) =>
      rtl ? (width - band.$2 - inset, width - band.$1 - inset) : (band.$1 - inset, band.$2 - inset);
}

class _DrumStage extends StatelessWidget {
  const _DrumStage(this.s, this.size);

  final SoundBoxesSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final SoundBoxesActivity a = s.drum;
    final bool rtl = rowDirectionOf(a.course, TextDirection.rtl) == TextDirection.rtl;
    final _Zones z = _Zones.of(AppLayout.of(context).board);
    final Rect picture = z.at(z.picture, rtl);
    final Rect drum = z.at(z.drum, rtl);
    final Rect check = z.at(z.check, rtl);
    final (double, double) band = z.bandAt(rtl);
    final double inset = z.inset;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        // On a tablet the zones were drawn on the whole card, whose rim is outside the room: nothing of them lies outside the card.
        clipBehavior: inset > 0 ? Clip.none : Clip.antiAlias,
        child: Stack(
          key: const Key('drum-stage'),
          clipBehavior: Clip.none,
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned.fromRect(
              rect: picture,
              child: PackSvg(a.assets.svg(a.picture), key: const Key('drum-picture')),
            ),
            Positioned.fromRect(rect: drum, child: _drum(drum.width)),
            // The hands of the second hint clap in a band that ends before the check mark.
            if (s.hands > 0)
              Positioned(
                left: band.$1,
                width: band.$2 - band.$1,
                top: z.handsY - inset,
                height: z.handsH,
                child: Row(
                  key: const Key('drum-hands'),
                  textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < s.hands; i++)
                      Icon(Icons.back_hand_rounded, size: z.handsH - 4, color: TokenColors.correctGlow),
                  ],
                ),
              ),
            Positioned(
              left: band.$1,
              width: band.$2 - band.$1,
              top: z.dotsY - inset,
              height: z.dot,
              child: Row(
                key: const Key('drum-dots'),
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < s.taps; i++) ...<Widget>[
                    if (i > 0) SizedBox(width: z.gap),
                    Container(
                      key: Key('drum-dot-$i'),
                      width: z.dot,
                      height: z.dot,
                      decoration: const BoxDecoration(color: TokenColors.correctGlow, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
            // "That's all": the check mark, alone at the end corner, below the drum.
            Positioned.fromRect(
              rect: check,
              child: PebbleButton(
                key: const Key('drum-done'),
                semanticLabel: He.drumDoneSemantics.text,
                size: check.width - 8,
                slop: 4,
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
