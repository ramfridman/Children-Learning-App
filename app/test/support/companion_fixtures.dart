import 'dart:io';

import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../../tool/pack_builder_lib.dart';
import 'character_fixtures.dart';
import 'pack_fixtures.dart';
import 'voice_fixtures.dart';

Character? _nitzi;

/// The house character, from the pack that ships in the app, verified with the real public key.
Future<Character> loadNitzi() async => _nitzi ??= Character.fromPack(
  await verifyPack(
    File('assets/characters/char-nitzi-1.0.0.nnpack').readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  ),
);

/// Every voice line the starter pack asks for, and the greeting of the map.
List<String> voiceLinesOfStarter() {
  final Set<String> ids = <String>{'core.greeting.hello'};
  for (final FileSystemEntity e in Directory('../content/starter').listSync()) {
    if (e is! File || !e.path.endsWith('.json')) continue;
    for (final RegExpMatch m in RegExp(r'"vo": "vo:([^"]+)"').allMatches(e.readAsStringSync())) {
      ids.add(m.group(1)!);
    }
  }
  return ids.toList()..sort();
}

/// Nitzi and the [friends] (family characters made fresh with a test key), each with a voice whose every line
/// is a tiny file that names its character and line (`mp3:<character>:<line>`), so a test can tell whose voice played.
Future<FixedCharacterSource> makeSource({List<String> friends = const <String>[], bool voices = true}) async {
  final PackKey key = await newTestKey();
  final Directory tmp = Directory.systemTemp.createTempSync('nn_companion_');
  try {
    final Character nitzi = await loadNitzi();
    final List<Character> all = <Character>[nitzi];
    for (final String id in friends) {
      all.add(await characterFrom(await buildCharacterPack(writeCharacterFolder(tmp, id), key), key));
    }
    final Map<String, VoiceBank> banks = <String, VoiceBank>{};
    if (voices) {
      for (final Character c in all) {
        final BuiltPack built = await buildVoicePack(key, c.id, <String, List<(int, int)>>{
          for (final String line in voiceLinesOfStarter()) line: <(int, int)>[(0, 0), (100, 1), (200, 0)],
        });
        banks[c.id] = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
      }
    }
    return FixedCharacterSource(characters: all, house: nitzi, voices: banks);
  } finally {
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}
