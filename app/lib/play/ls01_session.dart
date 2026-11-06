import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/token_types.dart';
import 'choice_row.dart';
import 'ls01_hand.dart';
import 'ls01_metrics.dart';
import 'template_session.dart';

/// What the modes of LS01 that are not a choice among options share (sort, pairs, spot, order tiles, the story line): the board of the
/// two zones, the metrics of the band, the hint's marks and hand, and the counter that stops a hint when the child moves on.
/// (The text stem, the cloze and the tap-all are choices and extend `ChoiceSession`, see `Ls01TapSession`.)
abstract class Ls01Session extends TemplateSession {
  Ls01Session(super.controller, this.activity, {this.band = Band.b, this.stress = true});

  final Activity activity;

  /// The presentation band of the course, not the content's band letter (docs/design/languages-l5-ls01.md section 3).
  final Band band;
  final bool stress;

  ActivitySpec? _spec;

  /// A hint's hand: where its fingertip is, a point of the board; null when there is no hand.
  Offset? handTip;

  /// A card a hint sends on its way (the copy that flies from the tray to its bin): what it looks like and where it is now, a rectangle of
  /// the board. The board layer moves it there; null when nothing flies.
  Widget? flightChild;
  Rect? flightRect;

  /// Changes whenever a hint starts or stops, so that the steps of an earlier hint do nothing.
  int run = 0;

  TextDirection get rowDirection => rowDirectionOf(activity.course, TextDirection.rtl);

  /// The story line uses the width of the tablet landscape (the zone A-wide).
  bool get wideZone => false;

  /// The board the session was last laid out on (the phone's until it has been).
  ActivitySpec get zones => _spec ?? ActivitySpec.phone;

  @override
  ActivitySpec layoutFor(ActivitySpec base) => _spec = withLs01Zones(base, band, wide: wideZone);

  Ls01Metrics get metrics => Ls01Metrics.of(band: band, spec: zones, course: activity.course);

  /// Where the stage's own origin is on the board (a card of a tablet has a 16 point lip), and the room inside it.
  Offset get stageOrigin =>
      zones.stage.topLeft + Offset(zones.stageIsCard ? 16 : 0, zones.stageIsCard ? 16 : 0);
  Size get stageRoom =>
      zones.stageIsCard ? Size(zones.stage.width - 32, zones.stage.height - 32) : zones.stage.size;

  /// Remembers the board the session is drawn on (the screen gives it to `buildStage` and `buildTiles`).
  void seen(ActivitySpec s) => _spec = s;

  /// Stops whatever a hint was doing.
  void endHint() {
    run++;
    handTip = null;
    flightChild = null;
    flightRect = null;
    clearHintMarks();
  }

  /// Takes a hint's marks off the screen.
  void clearHintMarks();

  @override
  void onReset() {
    endHint();
    resetState();
    notify();
  }

  /// The child may start the activity again from the beginning (a new activity, or after a mistake that restarts it).
  void resetState();

  @override
  void onHint() {
    endHint();
    playHint(controller.hintShown);
    notify();
  }

  /// Draws hint [level] (1 to 3). Level 1 and 2 never mark the answer; level 3 shows it, last (docs/design/languages-l5-ls01.md section 8).
  void playHint(int level);

  /// The third level ends: the hand leaves and the answer may carry its halo.
  void demoOver(int afterMs) {
    final int mine = run;
    later(Duration(milliseconds: afterMs), () {
      if (mine != run) return;
      handTip = null;
      controller.demoDone();
      notify();
    });
  }

  /// Runs [action] after [ms] unless another hint started meanwhile.
  void step(int ms, VoidCallback action) {
    final int mine = run;
    later(Duration(milliseconds: ms), () {
      if (mine != run) return;
      action();
      notify();
    });
  }

  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) {
    seen(spec);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) =>
          ls01HandLayer(handTip, spec, flight: flightChild, flightRect: flightRect) ??
          const SizedBox.shrink(),
    );
  }

  @override
  void onReplay() {}
}
