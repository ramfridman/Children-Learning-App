import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/tokens.g.dart';
import 'choice_row.dart';
import 'choice_session.dart';
import 'lesson_controller.dart' show LessonController;
import 'template_session.dart';

/// The sing-along template (LS12, docs/languages/frame.md section 2.3): a chant or a rhyme, spoken to a beat (no melody is built: any
/// tune is the owner's to approve). In **chant** mode the lines are said one after another, the pictures of a line light while it is
/// said, and a touch on a picture says its word; joining in is the child's own, nothing is asked and **nothing is written**; the replay
/// button sings it again from the start. In **rhyme** mode the verse is heard whole, stops before its last word, and the child chooses
/// the picture that ends it (scored, with the ladder: the end word again, the ends alone, the right picture lit); then the whole verse
/// is heard again.
class SingAlongSession extends ChoiceSession {
  SingAlongSession(LessonController controller, SingAlongActivity activity, {super.stress})
    : song = activity,
      super(controller, activity, activity) {
    // The song is its own sound: the replay button sings it again and says no line of its own while it is heard.
    controller.replayQuiet = true;
    later(Duration.zero, _begin);
  }

  final SingAlongActivity song;

  /// The line being said (chant), and the pictures that light now.
  int? litLine;
  Set<int> lit = <int>{};

  /// The rhyme has reached its gap: the question is asked and the choices are there.
  bool asking = false;

  /// The song is being sung; a new run (the replay button) takes over from the one before.
  int _run = 0;

  /// The picture touched last (it rings for a moment).
  int? touched;

  bool get rhyme => song.rhyme;

  void _begin() {
    if (disposed) return;
    rhyme ? _hear() : _sing();
  }

  /// The chant, line by line: its pictures light while the line is said, and a short rest follows each line.
  Future<void> _sing() async {
    final int run = ++_run;
    for (final (int i, ({List<String> clips, List<int> lights}) line) in song.lines.indexed) {
      litLine = i;
      lit = line.lights.toSet();
      notify();
      await sayAndWait(line.clips, replace: i == 0 && run > 1);
      if (disposed || run != _run) return;
      await pause(const Duration(milliseconds: 300));
      if (disposed || run != _run) return;
    }
    litLine = null;
    lit = <int>{};
    notify();
    controller.completePractice();
    later(TemplateSession.praisePause, controller.next);
  }

  /// The verse whole, then up to the gap, and then the question.
  Future<void> _hear() async {
    final int run = ++_run;
    lit = <int>{for (int i = 0; i < song.pictures.length; i++) i};
    notify();
    await sayAndWait(song.verse.whole);
    if (disposed || run != _run) return;
    await sayAndWait(song.verse.open);
    if (disposed || run != _run) return;
    lit = <int>{};
    asking = true;
    controller.replayQuiet = false;
    controller.askAnswer(song.question!);
    notify();
  }

  void touchPicture(int i) {
    touched = i;
    notify();
    final String? clip = song.pictures[i].clip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
    later(const Duration(milliseconds: 700), () {
      if (touched == i) {
        touched = null;
        notify();
      }
    });
  }

  // ---- the answer and the hints (rhyme) ----

  @override
  void onRight() {
    // The recast is said; then the whole verse, and the lesson goes on.
    later(TemplateSession.praisePause, () async {
      await sayAndWait(song.verse.full);
      if (!disposed) controller.next();
    });
  }

  @override
  void onReplay() {
    if (!rhyme) {
      _sing();
    } else if (asking) {
      pulseTiles();
    }
  }

  @override
  void onHint() {
    switch (hintPictureOf(activity)) {
      case HintPicture.replayPart:
        // The end word of the first line, said again.
        playClips?.call(song.verse.cue, replace: false);
      case HintPicture.endsAlone:
        _endsAlone();
      case HintPicture.demonstration:
        // "Show me": the whole verse is heard with the right picture lit (QA-L4-5).
        playClips?.call(song.verse.full, replace: false);
        endDemoIfShown();
      default:
        pulseTiles();
        endDemoIfShown();
    }
  }

  /// The end word of the first line before each option's word, the option lit while its pair is said: the ends alone, side by side.
  Future<void> _endsAlone() async {
    final int run = ++_run;
    for (final (int i, ChoiceOption o) in options.indexed) {
      litTile = i;
      notify();
      await sayAndWait(<String>[...song.verse.cue, ?o.clip]);
      if (disposed || run != _run) return;
    }
    litTile = null;
    notify();
  }

  @override
  void onReset() {
    super.onReset();
    asking = false;
    lit = <int>{};
    litLine = null;
  }

  // ---- layout ----

  @override
  ActivitySpec layoutFor(ActivitySpec base) => rhyme ? super.layoutFor(base) : withTallStage(base);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _SongStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) =>
      rhyme && asking ? choiceTiles(context, spec) : null;
}

/// The pictures of the song in a row, in the course's direction; those of the line being said are ringed and lifted.
class _SongStage extends StatelessWidget {
  const _SongStage(this.s, this.size);

  final SingAlongSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final SingAlongActivity a = s.song;
    final int n = a.pictures.length;
    final double box = math.min(size.height * 0.86, (size.width - 12) / n - 8);
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('song-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Center(
              child: Directionality(
                textDirection: s.rowDirection,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final (int i, ({String picture, String label, String? clip}) p)
                        in a.pictures.indexed)
                      _picture(context, i, p.picture, p.label, box),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _picture(BuildContext context, int i, String picture, String label, double box) {
    final bool lit = s.lit.contains(i);
    final bool touched = s.touched == i;
    final bool on = lit || touched;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: Key('song-picture-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => s.touchPicture(i),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedScale(
            scale: on ? 1.08 : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: Container(
              width: box,
              height: box,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: on ? TokenColors.sparkTint : TokenColors.paper.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(TokenRadius.lg),
                border: Border.all(
                  color: on ? TokenColors.correctGlow : TokenColors.hairline,
                  width: on ? 5 : 2,
                ),
              ),
              child: PackSvg(s.song.assets.svg(picture)),
            ),
          ),
        ),
      ),
    );
  }
}
