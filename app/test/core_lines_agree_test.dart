// B-42 part (a): the lines that the app speaks but `he.dart` writes (the bottle's 25 lines, the shared clip of the map
// bubble, the rest goodbye) are lines of `content/lines/core.he.json`, which `voice_gen` reads, so the one paid run voices
// them. The app asks for them by id; these tests keep the two sources equal, word for word, so a changed string cannot
// leave an old recording behind, and a clip the app asks for cannot be missing from the run.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/adventure_line.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import '../tool/voice_gen_lib.dart';

/// The core lines by id (without `vo:`).
Map<String, String> _core() => <String, String>{
  for (final SpokenLine l in coreLines(File('../content/lines/core.he.json'))) l.fileId: l.text,
};

/// Every stop of the bottle that has a line: each reason that names a land, in each land, and the play-again line once.
List<TodaysAdventure> _stops() => <TodaysAdventure>[
  for (final TrophyLand land in TrophyLand.values) ...<TodaysAdventure>[
    TodaysAdventure.lesson(land, 'x', AdventureReason.welcome),
    TodaysAdventure.revisit(land, 'x'),
    TodaysAdventure.lesson(land, 'x', AdventureReason.sameLand),
    TodaysAdventure.lesson(land, 'x', AdventureReason.otherLand),
  ],
  const TodaysAdventure.replay(TrophyLand.counting, 'x'),
];

void main() {
  final Map<String, String> core = _core();

  group('the bottle', () {
    test('each line the bottle can say is a core line with the same words', () {
      for (final TodaysAdventure stop in _stops()) {
        final AdventureLine line = adventureLine(stop)!;
        final String id = line.voice.substring('vo:'.length);
        expect(core[id], line.text, reason: '${line.voice} must say what the bottle shows');
      }
    });

    test('there is no bottle clip that the bottle never asks for, and none missing', () {
      final Set<String> asked = <String>{
        for (final TodaysAdventure s in _stops()) adventureLine(s)!.voice.substring('vo:'.length),
      };
      final Set<String> made = core.keys.where((String id) => id.startsWith('core.adventure.')).toSet();
      expect(made, asked);
      expect(made, hasLength(25), reason: '4 reasons x 6 lands, and the one play-again line');
    });
  });

  group('the other lines of he.dart that are spoken', () {
    test('the map bubble has one shared clip, the same with and without a name', () {
      expect(core['core.home.bubble'], He.homeBubbleNoName.text);
      expect(He.homeBubble.text, '{child}, ${He.homeBubbleNoName.text}', reason: 'the name clip comes first');
    });

    test('the rest goodbye', () {
      expect(core['core.rest.goodbye'], He.restGoodbye.text);
    });
  });

  group('the run', () {
    final Map<String, Object?> config =
        jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;
    final List<String> ids = <String>[
      for (final String id in core.keys)
        if (id.startsWith('core.adventure.') || id == 'core.home.bubble') 'vo:$id',
    ];

    test('the 26 clips are planned for both narrators and nothing blocks them', () {
      expect(ids, hasLength(26));
      final VoiceTexts texts = voiceTextsOf(
        content: Directory('../content/starter'),
        core: File('../content/lines/core.he.json'),
        master: readMaster(File('../docs/review/hebrew-master.csv').readAsStringSync()),
      );
      final Set<String> ready = <String>{for (final SpokenLine l in texts.ready) l.voId};
      final Map<String, String> blocked = <String, String>{
        for (final VoicedLine l in texts.blocked) l.voId: l.problem!,
      };
      for (final String id in ids) {
        expect(blocked[id], isNull, reason: '$id is blocked');
        expect(ready, contains(id));
      }
      for (final String narrator in <String>['nitzi', 'hero-son']) {
        final VoiceProfile profile = VoiceProfile.fromConfig(config, narrator);
        for (final String id in ids) {
          expect(profile.says(id), isTrue, reason: '$narrator says $id');
        }
      }
    });

    test('a spoken voice text carries no name and no placeholder', () {
      final VoiceTexts texts = voiceTextsOf(
        content: Directory('../content/starter'),
        core: File('../content/lines/core.he.json'),
        master: readMaster(File('../docs/review/hebrew-master.csv').readAsStringSync()),
      );
      final Map<String, String> spoken = texts.textById;
      for (final String id in ids) {
        expect(spoken[id], isNotEmpty, reason: id);
        expect(spoken[id], isNot(contains('{')), reason: id);
      }
    });
  });
}
