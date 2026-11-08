import 'package:flutter/widgets.dart';

import '../child/activity_shell.dart';
import '../engine/age.dart' show PresentationStage;
import 'layout.dart';
import 'token_types.dart';
import 'tokens.g.dart';

// What a screen looks like for one presentation stage P1 to P4 (B-29 step 6, docs/design/b29-steps5-6.md section 6.2). The numbers are the
// `stage` group of design/tokens.json; this file only reads them for the size class of the window. A lesson reads the stage once, when a
// session starts, and gives it to everything below it through [StageScope], so nothing changes under a child mid-activity.

class StageSpec {
  const StageSpec._(this.stage, this.token);

  /// The numbers of [stage].
  factory StageSpec.of(PresentationStage stage) => StageSpec._(stage, TokenStage.all[stage.index]);

  final PresentationStage stage;
  final StageToken token;

  int get maxChoices => token.maxChoices;

  /// The side of a plain answer tile, as drawn.
  double tile(SizeClass c) => c == SizeClass.tablet ? token.tileTablet : token.tilePhone;

  /// The gap between two tiles as drawn: twice the hit slop, so a row of tiles that each carry the slop has exactly this gap.
  double gap(SizeClass c) => c == SizeClass.tablet ? token.gapTablet : token.gapPhone;

  /// The room around a tile that still counts as touching it, each side.
  double slop(SizeClass c) => c == SizeClass.tablet ? token.hitSlopTablet : token.hitSlopPhone;

  /// The side of the square a tile answers to: the tile and its slop on each side (128 on a phone for P1 and P2: 2 cm).
  double hitArea(SizeClass c) => tile(c) + 2 * slop(c);

  /// The numeral on a tile.
  double numeral(SizeClass c) => c == SizeClass.tablet ? token.numeralTablet : token.numeralPhone;

  /// The size of the question's caption when it is drawn.
  double caption(SizeClass c) => switch (c) {
    SizeClass.tablet => token.captionTablet,
    SizeClass.phoneSE => token.captionPhoneSE,
    SizeClass.phone => token.captionPhone,
  };

  /// The least the caption shrinks to before its bubble widens.
  double captionFloor(SizeClass c) => caption(c) - token.captionFloorDrop;

  /// The speaker bubble that stands where a hidden caption would.
  double speaker(SizeClass c) => c == SizeClass.tablet ? token.speakerTablet : token.speakerPhone;

  /// Seconds of stillness before the first prompt, the second, the offer and the soft pause.
  Duration idle(int step) => Duration(seconds: token.idleSeconds[step.clamp(0, 3)]);

  Duration get transition => Duration(milliseconds: token.transitionMs);
  double get overshoot => token.overshoot;
  Duration get tier1 => Duration(milliseconds: token.tier1Ms);

  /// How long the praise stays before the next activity: the tier-1 celebration and the 800 ms that stay (1,600 for P1 and P2, as it has
  /// been, 1,500 for P3, 1,300 for P4).
  Duration get praise => const Duration(milliseconds: 800) + tier1;

  Duration get tier2 => Duration(milliseconds: token.tier2Ms);

  /// How long a tier-2 celebration plays before a tap may skip it; zero: a tap skips it at once.
  Duration get tier2SkipAfter => Duration(milliseconds: token.tier2SkipAfterMs);

  /// How many things may move at once.
  int get focal => token.focal;

  /// A land sign's name size, and the size it may shrink to.
  ({double size, double least}) sign(SizeClass c) {
    final List<double> s = c == SizeClass.tablet ? token.signTablet : token.signPhone;
    return (size: s[0], least: s[1]);
  }

  double get plusPebble => token.plusPebble;

  /// [base] with this stage's caption, numeral and tile numbers for the window's size class.
  ActivitySpec applyTo(ActivitySpec base, SizeClass c) =>
      base.withLook(captionFont: caption(c), numeralFont: numeral(c), tile: tile(c), slop: slop(c));
}

/// The look a lesson (or a home) is drawn in, and whether the question's Hebrew words are drawn. Nothing above a lesson provides one: a
/// widget that finds none draws the legacy sizes.
class StageScope extends InheritedWidget {
  const StageScope({super.key, required this.stage, required this.captionsShown, required super.child});

  final StageSpec stage;

  /// The words of the question are drawn; false: a speaker stands in their place.
  final bool captionsShown;

  static StageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StageScope>();

  @override
  bool updateShouldNotify(StageScope old) =>
      old.stage.stage != stage.stage || old.captionsShown != captionsShown;
}
