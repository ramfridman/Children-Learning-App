// A voice for the language fixtures: Nitzi's voice with exactly the lines asked for, each a tiny file that names its line
// (`mp3:<character>:<line>`), so a test can tell which clip played and in which order. Not a real voice: nothing is recorded.

import 'dart:convert';
import 'dart:typed_data';

import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../../tool/pack_builder_lib.dart';
import 'companion_fixtures.dart';
import 'pack_fixtures.dart';
import 'voice_fixtures.dart';

/// A voice bank holding the given `vo:` references (and nothing else).
Future<VoiceBank> bankOf(Iterable<String> voRefs, {String character = 'nitzi'}) async {
  final PackKey key = await newTestKey();
  final BuiltPack built = await buildVoicePack(key, character, <String, List<(int, int)>>{
    for (final String ref in voRefs) ref.substring('vo:'.length): <(int, int)>[(0, 0), (100, 1), (200, 0)],
  });
  return VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
}

/// Nitzi, with a voice that has the given lines.
Future<FixedCharacterSource> languageVoiceSource(Iterable<String> voRefs) async {
  final source = await makeSource(voices: false);
  return FixedCharacterSource(
    characters: source.characters,
    house: source.house,
    voices: <String, VoiceBank>{source.house.id: await bankOf(voRefs, character: source.house.id)},
  );
}

/// The line a played clip is: `eng.words.i01.prompt` for the bytes `mp3:nitzi:eng.words.i01.prompt`.
String lineOf(Uint8List played) => utf8.decode(played).split(':').last;

/// The lines a player has played, in order.
List<String> playedLines(Iterable<Uint8List> played) => <String>[for (final Uint8List p in played) lineOf(p)];
