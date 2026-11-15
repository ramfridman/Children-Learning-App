import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../characters/character.dart' show CharacterState;
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'choice_row.dart' show withMeetStage;
import 'meet_layout.dart';
import 'say_step.dart';
import 'speaking_badge.dart';
import 'template_session.dart';

/// The Meet screen (LS09 teach mode, docs/design/l7-meet-find.md section 3): the screen that introduces one new word to a new learner. One
/// big picture and nothing to choose. The beats are paced by the voice, and the screen is never a question: no lamp, no "show me", nothing
/// can be wrong, and nothing is written (the microphone is feedback only, never evidence).
///
///   opener (first word of a set) - the word - its Hebrew meaning, said once (or the Hebrew explaining sentence) - the word again -
///   "let's say it together" and the word - the child's turn
///
/// "I said it" and the microphone arrive with "let's say it together" and go on to close the screen; touching the picture plays the word and
/// never moves on (during the first beats it only squishes, so that no beat is cut and the meaning is never lost). The words met before it in
/// the set stand in a strip at the side and say their words when touched. A teach screen of the old kind (no `say.meet`) says its one line,
/// "let's say it together" and the word, and has the controls from the start.
class MeetSession extends TemplateSession {
  MeetSession(
    super.controller,
    this.activity, {
    this.say,
    this.showWord = false,
    this.breath = const Duration(milliseconds: 400),
  }) {
    controller.replayQuiet = true;
    say?.addListener(_onSay);
    // The voice and the lesson screen are given to the session just after it is made: start after that.
    later(Duration.zero, () => unawaited(_run()));
  }

  final SayItActivity activity;

  /// The microphone side, or null when the parent's voice switch is off (or the model is not on the phone).
  final SayStepController? say;

  /// The word is printed in a chip under the bubble's line from the third beat on (`meetShowsWord`).
  final bool showWord;

  /// The pause between two beats: the look's (400, 300 or 250 ms).
  final Duration breath;

  /// A beat lasts at least this long, so that a line that is not voiced yet (pending) still has its pause, as every pending line has.
  static const Duration beatLeast = Duration(milliseconds: 1200);

  /// The longest a beat waits for a voice that never finishes.
  static const Duration beatMost = Duration(seconds: 8);

  /// How long the picture's rim shows `spark` at the close, before the next screen.
  static const Duration rimTime = Duration(milliseconds: 400);

  /// How long the "I said it" tile is still after the child's turn begins before the word is said once more.
  static const Duration listenPause = Duration(milliseconds: 3200);

  MeetData? get _meet => activity.meet;

  MeetBeat _beat = MeetBeat.hearing;
  bool _acted = false;
  bool _closing = false;
  bool _rim = false;
  bool _pressed = false;
  bool _breathing = false;

  /// The picture (-1), or the strip's thumbnail with that index, is saying its word now (the speaking badge shows on it).
  int? _speaking;

  /// The beat the screen is at.
  MeetBeat get beat => _beat;

  /// "I said it" and the microphone are there from "let's say it together" until the close.
  bool get controlsShown => !_closing && _beat.index >= MeetBeat.together.index;

  /// A touch on the picture says the word (from the child's turn): before it, only a squish.
  bool get touchSpeaks => _beat.index >= MeetBeat.yourTurn.index;

  bool get hasMic => say != null && say!.state != SayState.unavailable;

  /// The child has said it (or tapped "I said it"): the controls are gone and the screen is closing or about to.
  bool get acted => _acted;

  /// Which picture is speaking: -1 the card, otherwise the index of the thumbnail; null for none.
  int? get speaking => _speaking;

  bool get rim => _rim;

  /// The guide's pose: waving at the opener, talking through the beats, listening at the child's turn, glad at the close.
  CharacterState get pose => _closing
      ? CharacterState.encourage
      : _beat == MeetBeat.opening
      ? CharacterState.wave
      : touchSpeaks
      ? CharacterState.listen
      : CharacterState.talk;

  // ---- the beats ----

  Future<void> _run() async {
    final MeetData? m = _meet;
    if (m == null) {
      // A teach screen of the old kind: its one line is playing, and the controls are there from the start.
      _beat = MeetBeat.together;
      notify();
      await _dwell();
      if (!disposed) _toTurn();
      return;
    }
    final bool opened = m.first && m.opener != null;
    _beat = opened ? MeetBeat.opening : MeetBeat.hearing;
    _speaking = opened ? null : -1;
    notify();
    await _dwell(); // the controller has said the first beat
    if (disposed) return;
    if (opened) await _then(MeetBeat.hearing, m.hear ?? _wordOnly(''), badge: true);
    _speaking = null;
    final Spoken? meaning = m.meaning ?? m.explain;
    if (meaning != null && !disposed) await _then(MeetBeat.meaning, meaning);
    if (disposed) return;
    await _then(MeetBeat.again, _wordOnly(m.hear?.caption ?? '', chip: true), badge: true);
    if (disposed) return;
    await _then(MeetBeat.together, _together(), badge: true);
    if (disposed) return;
    _toTurn();
  }

  /// A beat that follows another one: a breath, then the line, which the guide says while the voice paces the screen.
  Future<void> _then(MeetBeat beat, Spoken line, {bool badge = false}) async {
    await pause(breath);
    if (disposed || _closing) return;
    _beat = beat;
    _speaking = badge ? -1 : null;
    controller.speak(line);
    notify();
    await _dwell();
    if (disposed) return;
    _speaking = null;
    notify();
  }

  /// The beats are over: it is the child's turn. If they have said it (or tapped), the screen closes; otherwise after a pause the voice says
  /// the word once more.
  void _toTurn() {
    if (_closing) return;
    _beat = MeetBeat.yourTurn;
    notify();
    if (_acted) {
      unawaited(_close(afterLine: false));
      return;
    }
    later(listenPause, () {
      if (_acted || _closing) return;
      _speaking = -1;
      controller.speak(_wordOnly(_together().caption, chip: true));
      unawaited(_dwell().then((_) => _clearSpeaking(-1)));
      notify();
    });
  }

  /// The line that has just been asked of the voice has been said (or its pending pause is over).
  Future<void> _dwell() => Future.wait(<Future<void>>[pause(beatLeast), _quiet()]);

  Future<void> _quiet() {
    final Future<void> Function()? quiet = untilQuiet;
    return quiet == null ? Future<void>.value() : Future.any(<Future<void>>[quiet(), pause(beatMost)]);
  }

  /// The word alone, under [caption]; with the chip when the rule allows it.
  Spoken _wordOnly(String caption, {bool chip = false}) =>
      Spoken(vo: activity.wordClip, caption: caption, show: chip ? _written : null);

  /// "Let's say it together" and the word, with the chip when the rule allows it.
  Spoken _together() {
    final Spoken t = activity.together;
    return Spoken(vo: t.vo, caption: t.caption, target: t.target, target2: t.target2, show: _written);
  }

  String? get _written => showWord ? (_meet?.written ?? _plain) : null;

  String get _plain => activity.forms.first;

  void _clearSpeaking(int which) {
    if (_speaking == which) {
      _speaking = null;
      notify();
    }
  }

  // ---- the child ----

  /// "I said it": practice only. Nothing is written. A tap while the beats play lets the word finish, then the screen closes.
  void saidIt() {
    if (_acted || _closing || !controlsShown) return;
    _acted = true;
    notify();
    if (touchSpeaks) unawaited(_close(afterLine: false));
  }

  /// The microphone's answer: heard or not, the voice has said its line ("heard" and the word, or "together" and the word) and the screen closes
  /// after it. Nothing is written for it.
  void _onSay() {
    final SayState? s = say?.state;
    if (s != SayState.heard && s != SayState.together) return;
    if (_acted || _closing) return;
    _acted = true;
    notify();
    if (touchSpeaks) unawaited(_close(afterLine: true));
  }

  Future<void> _close({required bool afterLine}) async {
    if (_closing) return;
    _closing = true;
    notify();
    if (afterLine) {
      await pause(const Duration(milliseconds: 100));
      await _quiet();
    }
    if (disposed) return;
    _rim = true;
    notify();
    await pause(rimTime);
    if (!disposed) controller.next();
  }

  /// The picture was touched: before the child's turn it squishes and nothing more (no beat is cut, the meaning is never lost), then it
  /// says its word again, and never moves on.
  void touchPicture() {
    if (touchSpeaks && !_closing) {
      unawaited(_sayWord(activity.wordClip, -1));
    } else {
      _press();
    }
  }

  /// A thumbnail of the strip was touched: the same, for its own word.
  void touchThumb(int i) {
    final List<MeetWord> earlier = _meet?.earlier ?? const <MeetWord>[];
    if (i >= earlier.length) return;
    if (touchSpeaks && !_closing) {
      unawaited(_sayWord(earlier[i].clip, i));
    } else {
      _press();
    }
  }

  void _press() {
    _pressed = true;
    notify();
    later(const Duration(milliseconds: 120), () {
      _pressed = false;
      notify();
    });
  }

  bool get pressed => _pressed;

  /// Says [clip] at once, with the speaking badge on [which] while it plays (at most 1.5 s).
  Future<void> _sayWord(String clip, int which) async {
    _speaking = which;
    notify();
    final FutureOr<void> played = playClips?.call(<String>[clip], replace: true);
    await Future.any(<Future<void>>[
      played is Future<void> ? played : pause(const Duration(milliseconds: 700)),
      pause(const Duration(milliseconds: 1500)),
    ]);
    if (!disposed) _clearSpeaking(which);
  }

  /// The idle ladder's first and second prompt: the guide says "let's say it together" and the word again, and the "I said it" tile breathes
  /// once. No hand: a hand pointing at the picture would teach "touch the picture to go on" (section 3.6).
  void idlePrompt() {
    if (_closing || !controlsShown) return;
    controller.speak(_together());
    _breathing = true;
    notify();
    later(const Duration(milliseconds: 600), () {
      _breathing = false;
      notify();
    });
  }

  bool get tileBreathes => _breathing;

  @override
  void onReset() {}

  /// The replay button says the word from the child's turn on; before it nothing (the meaning is never said twice).
  @override
  void onReplay() {
    if (touchSpeaks && !_closing) unawaited(_sayWord(activity.wordClip, -1));
  }

  @override
  void onHint() => onReplay();

  // ---- the stage ----

  @override
  ActivitySpec layoutFor(ActivitySpec base) => withMeetStage(base);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => _MeetStage(this, size, spec),
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final bool shown = controlsShown && !_acted;
      final bool still = MediaQuery.disableAnimationsOf(c);
      return IgnorePointer(
        ignoring: !shown,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: still ? const Duration(milliseconds: 120) : const Duration(milliseconds: 220),
          child: AnimatedSlide(
            offset: shown ? Offset.zero : const Offset(0, 8 / 96),
            duration: still ? Duration.zero : const Duration(milliseconds: 220),
            child: Center(
              child: _SaidItTile(session: this, spec: spec),
            ),
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    say?.removeListener(_onSay);
    super.dispose();
  }
}

/// The beats of a Meet screen, in order (the design's M0 to M5; the close is [MeetSession.rim]).
enum MeetBeat { opening, hearing, meaning, again, together, yourTurn }

/// The "I said it" tile (docs/design/l7-meet-find.md section 4.1): the glyph of a voice at its start, then the word, 184 wide on the phones
/// and 200 on the tablets, the look's height. The glyph tells a child who cannot read what the tile is about.
class _SaidItTile extends StatelessWidget {
  const _SaidItTile({required this.session, required this.spec});

  final MeetSession session;
  final ActivitySpec spec;

  @override
  Widget build(BuildContext context) {
    final bool tablet = spec.stageIsCard;
    final Widget tile = AnswerTile(
      key: const Key('say-done'),
      semanticLabel: He.sayDone.text,
      onPressed: session.saidIt,
      width: tablet ? 200 : 184,
      size: spec.tileSize,
      hitPadding: EdgeInsets.symmetric(horizontal: 4, vertical: spec.tileSlop),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.record_voice_over_rounded, size: tablet ? 36 : 32, color: TokenColors.ink),
          const SizedBox(width: 8),
          Text(He.sayDone.text, style: AppText.fixed(size: tablet ? 32 : 28, weight: 600)),
        ],
      ),
    );
    final bool still = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: session.tileBreathes && !still ? 1.06 : 1,
      duration: const Duration(milliseconds: 300),
      child: tile,
    );
  }
}

/// The aspect (width over height) of a picture of the pack, from its viewBox; square when it names none.
double svgAspect(String svg) {
  final RegExpMatch? m = RegExp(r'viewBox="\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)').firstMatch(svg);
  final double? w = m == null ? null : double.tryParse(m.group(1)!);
  final double? h = m == null ? null : double.tryParse(m.group(2)!);
  return w == null || h == null || h <= 0 ? 1 : w / h;
}

class _MeetStage extends StatelessWidget {
  const _MeetStage(this.s, this.size, this.spec);

  final MeetSession s;
  final Size size;
  final ActivitySpec spec;

  @override
  Widget build(BuildContext context) {
    final SayItActivity a = s.activity;
    final MeetData? meet = a.meet;
    final String svg = a.assets.svg(a.picture);
    final bool tablet = spec.stageIsCard;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final MeetLayout layout = MeetLayout(
      stage: size,
      aspect: svgAspect(svg),
      earlier: meet?.earlier.length ?? 0,
      tablet: tablet,
      lookA: spec.tileSize >= 96,
    );
    final double disc = tablet ? SpeakingBadge.tabletDisc : 40;
    final Rect card = layout.card;
    final Widget picture = PackSvg(svg);
    final Widget cardBody = Container(
      key: const Key('meet-card'),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.xl),
        border: Border.all(color: s.rim ? TokenColors.spark : TokenColors.cardLip, width: s.rim ? 4 : 2),
        boxShadow: clayShadows(TokenColors.cardLip),
      ),
      padding: const EdgeInsets.all(MeetLayout.padding),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: picture),
          if (meet?.focus != null && s.beat.index >= MeetBeat.hearing.index)
            Positioned.fill(child: _Focus(meet!.focus!)),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: a.altText,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final (int i, Rect r) in layout.strip.indexed)
            Positioned.fromRect(
              rect: r,
              child: _Thumb(
                key: Key('meet-thumb-$i'),
                svg: a.assets.svg(meet!.earlier[i].sprite),
                speaking: s.speaking == i,
                disc: 28,
                pressed: s.pressed,
                onTap: () => s.touchThumb(i),
              ),
            ),
          Positioned.fromRect(
            rect: card,
            // The card arrives: it grows in (0.92 to 1) and fades in; with reduce motion it only fades (the design's section 7).
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: still ? 0 : 0.92, end: 1),
              duration: still ? const Duration(milliseconds: 120) : const Duration(milliseconds: 450),
              curve: still ? Curves.linear : Curves.easeOutBack,
              builder: (BuildContext c, double v, Widget? child) => Opacity(
                opacity: still ? v : ((v - 0.92) / 0.08).clamp(0.0, 1.0),
                child: Transform.scale(scale: still ? 1 : v, child: child),
              ),
              child: GestureDetector(
                key: const Key('say-picture'),
                behavior: HitTestBehavior.opaque,
                onTap: s.touchPicture,
                child: AnimatedScale(
                  scale: s.speaking == -1 && !still
                      ? 1.03
                      : s.pressed
                      ? 0.94
                      : 1,
                  duration: const Duration(milliseconds: 160),
                  child: cardBody,
                ),
              ),
            ),
          ),
          // The badge stands at the card's top start corner (the interface is right to left: the right), 10 inside it so that it overlaps.
          Positioned(
            left: card.right - disc / 2 - 10,
            top: card.top - disc / 2 + 10,
            child: SpeakingBadge(
              on: s.speaking == -1,
              disc: disc,
              icon: tablet ? SpeakingBadge.tabletIcon : 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    super.key,
    required this.svg,
    required this.speaking,
    required this.disc,
    required this.pressed,
    required this.onTap,
  });

  final String svg;
  final bool speaking;
  final double disc;
  final bool pressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedScale(
      scale: pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 120),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(TokenRadius.md),
                border: Border.all(color: TokenColors.hairline, width: 2),
                boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 4),
              ),
              padding: const EdgeInsets.all(6),
              child: PackSvg(svg),
            ),
          ),
          Positioned(
            left: -disc / 2 + 10,
            top: -disc / 2 + 10,
            child: SpeakingBadge(on: speaking, disc: disc, icon: 18),
          ),
        ],
      ),
    ),
  );
}

/// The ring round the part of a story page that the word names (the Hebrew Meet page): 4 points, `spark`, from the first beat to the close.
/// No scrim and no dimming of the rest: the story stays whole.
class _Focus extends StatelessWidget {
  const _Focus(this.focus);

  final Rect focus;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (BuildContext c, BoxConstraints box) => Stack(
        children: <Widget>[
          Positioned(
            key: const Key('meet-focus'),
            left: focus.left * box.maxWidth,
            top: focus.top * box.maxHeight,
            width: math.min(focus.width, 1) * box.maxWidth,
            height: math.min(focus.height, 1) * box.maxHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TokenColors.spark, width: 4),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
