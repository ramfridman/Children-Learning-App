// The small data types that the generated `tokens.g.dart` is made of. The values come from
// `design/tokens.json`; nothing here is a design decision.

/// Age band of the child profile: A is 3 to 4, B is 5 to 6, C is 7 to 8.
enum Band { a, b, c }

/// A type style for the child space: sizes differ between phone and tablet.
class TypeToken {
  const TypeToken({
    required this.family,
    required this.weight,
    required this.lineHeight,
    required this.phoneSize,
    required this.tabletSize,
  });

  /// Either `display` (Secular One) or `text` (Heebo).
  final String family;
  final int weight;
  final double lineHeight;
  final double phoneSize;
  final double tabletSize;
}

/// A type style of the parent area: one size on every device.
class ParentTypeToken {
  const ParentTypeToken({required this.weight, required this.size, required this.lineHeight});

  final int weight;
  final double size;
  final double lineHeight;
}

/// Touch sizes for one age band (design spec 6.1).
class BandTouch {
  const BandTouch({
    required this.minControl,
    required this.answerPhone,
    required this.answerTablet,
    required this.gapPhone,
    required this.gapTablet,
    required this.hitSlop,
    required this.maxChoices,
  });

  final double minControl;
  final double answerPhone;
  final double answerTablet;
  final double gapPhone;
  final double gapTablet;
  final double hitSlop;
  final int maxChoices;
}

/// What one presentation stage (P1 to P4) looks like (B-29, docs/design/b29-steps5-6.md section 6.2). Sizes are in points, phone and tablet;
/// the gap between two answer tiles is twice the hit slop, so a row of tiles that each carry the slop has exactly this gap.
class StageToken {
  const StageToken({
    required this.maxChoices,
    required this.tilePhone,
    required this.tileTablet,
    required this.gapPhone,
    required this.gapTablet,
    required this.hitSlopPhone,
    required this.hitSlopTablet,
    required this.numeralPhone,
    required this.numeralTablet,
    required this.captionPhone,
    required this.captionPhoneSE,
    required this.captionTablet,
    required this.captionFloorDrop,
    required this.speakerPhone,
    required this.speakerTablet,
    required this.idleSeconds,
    required this.transitionMs,
    required this.overshoot,
    required this.tier1Ms,
    required this.tier2Ms,
    required this.tier2SkipAfterMs,
    required this.focal,
    required this.signPhone,
    required this.signTablet,
    required this.plusPebble,
  });

  final int maxChoices;
  final double tilePhone;
  final double tileTablet;
  final double gapPhone;
  final double gapTablet;
  final double hitSlopPhone;
  final double hitSlopTablet;
  final double numeralPhone;
  final double numeralTablet;
  final double captionPhone;
  final double captionPhoneSE;
  final double captionTablet;
  final double captionFloorDrop;
  final double speakerPhone;
  final double speakerTablet;

  /// Seconds of stillness before the first prompt, the second, the offer and the soft pause.
  final List<int> idleSeconds;
  final int transitionMs;
  final double overshoot;
  final int tier1Ms;
  final int tier2Ms;

  /// How long a tier-2 celebration plays before a tap may skip it; 0 means a tap skips at once.
  final int tier2SkipAfterMs;

  /// How many things may move at once.
  final int focal;

  /// The size of a land sign's name and the size it may shrink to, on a phone and on a tablet.
  final List<double> signPhone;
  final List<double> signTablet;
  final double plusPebble;
}

/// The reading size of one kind of text face of a language course in one band, in points: the Hebrew course (Heebo) and English or
/// Russian (the teaching font), on a phone and on a tablet.
class ReadingSize {
  const ReadingSize({
    required this.hePhone,
    required this.heTablet,
    required this.targetPhone,
    required this.targetTablet,
  });

  final double hePhone;
  final double heTablet;
  final double targetPhone;
  final double targetTablet;

  double of({required bool hebrew, required bool tablet}) =>
      hebrew ? (tablet ? heTablet : hePhone) : (tablet ? targetTablet : targetPhone);
}

/// Layout numbers of a window size class.
class LayoutClass {
  const LayoutClass({
    required this.contentMargin,
    required this.topBarHeight,
    required this.topBarControlTop,
    required this.guideRailWidth,
  });

  final double contentMargin;
  final double topBarHeight;
  final double topBarControlTop;
  final double guideRailWidth;
}

/// A reference device from the design boards, in logical points.
class DeviceToken {
  const DeviceToken({
    required this.width,
    required this.height,
    required this.safeStart,
    required this.safeEnd,
    required this.safeTop,
    required this.safeBottom,
  });

  final double width;
  final double height;
  final double safeStart;
  final double safeEnd;
  final double safeTop;
  final double safeBottom;
}
