import '../engine/course.dart';
import '../rewards/award.dart';
import '../rewards/names.dart';
import '../strings/he.dart';
import '../world/adventure_land.dart';
import '../world/todays_adventure.dart';

/// What the companion says in the home island's bubble when the child taps the bottle (B-39, rule section 8): the line for
/// the stop's reason, with the stop's land in it.
///
/// [text] is the bubble (with niqqud), [semantics] what a screen reader says (plain), [voice] the id of the clip that is
/// played if the pack has one (none is recorded yet: the line is then only written).
typedef AdventureLine = ({String text, String semantics, String voice});

/// The line for [stop], or null when it has none (`nothing`: the island stays calm).
///
/// `{land}` is the one placeholder here that is filled on the device, and only ever from the land names of `He.land*`
/// (through `landName` and `landSemanticsName`); a test keeps it so. Nothing about the child goes into the line.
AdventureLine? adventureLine(TodaysAdventure stop) {
  final (Str, Str)? pair = switch (stop.reason) {
    AdventureReason.welcome => (He.adventureWelcome, He.adventureWelcomeSemantics),
    AdventureReason.callForHelp ||
    AdventureReason.checkVisit => (He.adventureCallForHelp, He.adventureCallForHelpSemantics),
    AdventureReason.sameLand => (He.adventureSameLand, He.adventureSameLandSemantics),
    AdventureReason.otherLand => (He.adventureOtherLand, He.adventureOtherLandSemantics),
    AdventureReason.playAgain => (He.adventurePlayAgain, He.adventurePlayAgainSemantics),
    AdventureReason.nothing => null,
  };
  final AdventureLand? place = stop.land;
  if (pair == null || place == null) return null;
  // A stop in a language has one line for each language, whatever the reason: it says what the child will do, never "again",
  // "new" or "help", and has no variable (proposals of the hebrew-text-editor, waiting for the owner's pick).
  if (place is LanguageLand) {
    final (Str, Str) line = switch (place.course) {
      Course.eng => (He.adventureLangEnglish, He.adventureLangEnglishSemantics),
      Course.rus => (He.adventureLangRussian, He.adventureLangRussianSemantics),
      _ => (He.adventureLangHebrew, He.adventureLangHebrewSemantics),
    };
    return (text: line.$1.text, semantics: line.$2.text, voice: 'vo:core.adventure.lang.${place.course}');
  }
  if (place is! TrophyLand) return null;
  final TrophyLand land = place;
  return (
    text: pair.$1.fill(<String, String>{'land': landName(land).text}),
    semantics: pair.$2.fill(<String, String>{'land': landSemanticsName(land).text}),
    // The play-again line names no land, so its clip is one for every land; the others are one clip per land.
    voice: stop.reason == AdventureReason.playAgain
        ? 'vo:core.adventure.${_voiceWord(stop.reason)}'
        : 'vo:core.adventure.${_voiceWord(stop.reason)}.${land.name}',
  );
}

/// The reason as a voice id writes it (a pack id has only `a-z`, digits, `_` and `.`): `callForHelp` is `call_for_help`.
String _voiceWord(AdventureReason r) =>
    r.name.replaceAllMapped(RegExp('[A-Z]'), (Match m) => '_${m[0]!.toLowerCase()}');
