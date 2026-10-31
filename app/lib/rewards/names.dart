import '../strings/he.dart';
import '../strings/niqqud.dart';
import 'award.dart';

/// A land's name as the child's strings write it (with niqqud).
Str landName(TrophyLand land) => switch (land) {
  TrophyLand.counting => He.landCounting,
  TrophyLand.colors => He.landColors,
  TrophyLand.shapes => He.landShapes,
  TrophyLand.logic => He.landLogic,
  TrophyLand.robots => He.landRobots,
  TrophyLand.market => He.landMarket,
};

/// The same without niqqud, as a screen reader is given it (its own strings, never a changed copy).
Str landSemanticsName(TrophyLand land) => switch (land) {
  TrophyLand.counting => He.landCountingSemantics,
  TrophyLand.colors => He.landColorsSemantics,
  TrophyLand.shapes => He.landShapesSemantics,
  TrophyLand.logic => He.landLogicSemantics,
  TrophyLand.robots => He.landRobotsSemantics,
  TrophyLand.market => He.landMarketSemantics,
};

/// The same, for the adult screens: plain text.
String landNamePlain(TrophyLand land) => withoutNiqqud(landName(land).text);

/// A trophy's tier for the adult screens: plain text.
String tierNamePlain(TrophyTier tier) => switch (tier) {
  TrophyTier.bronze => He.prizesBronze.text,
  TrophyTier.silver => He.prizesSilver.text,
  TrophyTier.gold => He.prizesGold.text,
};

/// A trophy as the adult screens name it: its tier and its land, in plain text.
String trophyNamePlain(TrophyLand land, TrophyTier tier) => '${tierNamePlain(tier)} · ${landNamePlain(land)}';
