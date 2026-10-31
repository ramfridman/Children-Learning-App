import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/adventure_line.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/names.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/todays_adventure.dart';

void main() {
  const TrophyLand land = TrophyLand.shapes;

  test('each reason has its own line, with the land\'s name in it', () {
    final Map<AdventureReason, TodaysAdventure> stops = <AdventureReason, TodaysAdventure>{
      AdventureReason.welcome: const TodaysAdventure.lesson(land, 'x', AdventureReason.welcome),
      AdventureReason.callForHelp: const TodaysAdventure.revisit(land, 'SHP-A-01'),
      AdventureReason.sameLand: const TodaysAdventure.lesson(land, 'x', AdventureReason.sameLand),
      AdventureReason.otherLand: const TodaysAdventure.lesson(land, 'x', AdventureReason.otherLand),
      AdventureReason.playAgain: const TodaysAdventure.replay(land, 'x'),
    };
    final Map<AdventureReason, Str> texts = <AdventureReason, Str>{
      AdventureReason.welcome: He.adventureWelcome,
      AdventureReason.callForHelp: He.adventureCallForHelp,
      AdventureReason.sameLand: He.adventureSameLand,
      AdventureReason.otherLand: He.adventureOtherLand,
      AdventureReason.playAgain: He.adventurePlayAgain,
    };
    final Set<String> seen = <String>{};
    for (final MapEntry<AdventureReason, TodaysAdventure> e in stops.entries) {
      final AdventureLine line = adventureLine(e.value)!;
      expect(line.text, texts[e.key]!.fill(<String, String>{'land': He.landShapes.text}), reason: '${e.key}');
      expect(line.text, isNot(contains('{')));
      expect(line.semantics, isNot(contains('{')));
      // The screen-reader label has no niqqud (U+05B0..U+05C7).
      expect(line.semantics, isNot(matches(RegExp('[ְ-ׇ]'))), reason: 'the label is plain');
      expect(seen.add(line.text), isTrue, reason: 'no two reasons share a line');
    }
    expect(adventureLine(stops[AdventureReason.sameLand]!)!.semantics, contains(He.landShapesSemantics.text));
    expect(
      adventureLine(stops[AdventureReason.playAgain]!)!.text,
      He.adventurePlayAgain.text,
      reason: 'the play-again line has no land in it',
    );
  });

  test('nothing to play has no line, and the island stays calm', () {
    expect(adventureLine(const TodaysAdventure.none()), isNull);
  });

  test('every land has its name in the line, from the land constants only', () {
    for (final TrophyLand l in TrophyLand.values) {
      final AdventureLine line = adventureLine(TodaysAdventure.lesson(l, 'x', AdventureReason.otherLand))!;
      expect(line.text, contains(landName(l).text));
      expect(line.semantics, contains(landSemanticsName(l).text));
    }
  });

  test('the voice id names the reason and the land, and the play-again clip is one for every land', () {
    expect(
      adventureLine(const TodaysAdventure.lesson(TrophyLand.counting, 'x', AdventureReason.welcome))!.voice,
      'vo:core.adventure.welcome.counting',
    );
    expect(
      adventureLine(const TodaysAdventure.revisit(TrophyLand.market, 'MATH-A-01'))!.voice,
      'vo:core.adventure.callForHelp.market',
    );
    expect(
      adventureLine(const TodaysAdventure.replay(TrophyLand.logic, 'x'))!.voice,
      'vo:core.adventure.playAgain',
    );
  });
}
