import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

void main() {
  late VoiceBank friend;
  late VoiceBank narrator;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    Future<VoiceBank> bank(String id, List<String> lines) async => VoiceBank.fromPack(
      await verifyPack(
        (await buildVoicePack(key, id, <String, List<(int, int)>>{
          for (final String l in lines) l: <(int, int)>[(0, 0), (100, 1)],
        })).bytes,
        publicKey: key.publicKey,
      ),
    );
    friend = await bank('tower-tamir', <String>['core.greeting.hello']);
    narrator = await bank('nitzi', <String>['core.greeting.hello', 'next.after.2.prompt']);
  });

  test(
    'a friend with only its own greeting says that line itself and borrows the narrator for a lesson line',
    () {
      final VoiceBank b = VoiceBank.withFallback(friend, narrator);
      expect(b.characterId, 'tower-tamir');
      expect(String.fromCharCodes(b.clip('vo:core.greeting.hello')!.mp3), contains('tower-tamir'));
      expect(String.fromCharCodes(b.clip('vo:next.after.2.prompt')!.mp3), contains('nitzi'));
      expect(b.has('vo:next.after.2.prompt'), isTrue);
      expect(b.clip('vo:no.such.line'), isNull);
    },
  );

  test('a bank that stands alone has no fallback and keeps saying nothing for a line it lacks', () {
    expect(friend.clip('vo:next.after.2.prompt'), isNull);
    expect(friend.fallback, isNull);
  });
}
