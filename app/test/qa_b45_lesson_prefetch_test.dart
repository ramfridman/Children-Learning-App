// QA (B-45): opening a lesson makes the lesson screen ask the voice for the packs of the lines that lesson uses, and with a lazy
// narrator voice the part pack is read once and the first question is spoken from it. The developer's gap: nothing tested that
// `LessonScreen` itself calls `prefetch`. Real starter pack, real LessonScreen, fakes for sound and for packs.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/characters/resolver.dart';
import 'package:nitznutz/content/models.dart' show PackContent;
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/voice/voice_lines.dart';

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/companion_fixtures.dart';
import 'support/harness.dart';
import 'support/pack_fixtures.dart';
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

const String child = 'p-1';

/// A director that remembers what it was asked to prefetch (and loads nothing).
class _SpyDirector extends VoiceDirector {
  _SpyDirector({required super.player});

  final List<List<String>> prefetched = <List<String>>[];

  @override
  Future<void> prefetch(Iterable<String> voIds) {
    prefetched.add(voIds.toList());
    return super.prefetch(voIds);
  }
}

/// The house source with Nitzi's voice replaced by [voice].
class _Source implements CharacterSource {
  _Source(this._inner, this._voice);

  final CharacterSource _inner;
  final VoiceBank _voice;

  @override
  Future<CharacterResolver> resolver() => _inner.resolver();

  @override
  Future<VoiceBank> voice(String characterId) async =>
      characterId == 'nitzi' ? _voice : VoiceBank.empty(characterId);
}

Future<void> _untilFrame(WidgetTester tester) async {
  for (int i = 0; i < 40; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(ActivityFrame).evaluate().isNotEmpty) break;
  }
}

void main() {
  testWidgets('LessonScreen asks the voice to prefetch the lines of the lesson it opens', (
    WidgetTester tester,
  ) async {
    final PackContent content = await loadStarter();
    final _SpyDirector spy = _SpyDirector(player: FakePlayer());
    addTearDown(spy.dispose);
    final AppRig rig = AppRig(extraOverrides: <Override>[voiceDirectorProvider.overrideWithValue(spy)]);
    await rig.seedFinishedSetup();
    addTearDown(rig.db.close);
    await pumpScreen(
      tester,
      ProviderScope(
        overrides: rig.overrides,
        child: const LessonScreen(profileId: child),
      ),
    );
    await _untilFrame(tester);
    expect(find.byType(ActivityFrame), findsOneWidget);

    expect(spy.prefetched, hasLength(1), reason: 'once, when the controller is made');
    final List<String> asked = spy.prefetched.single;
    expect(asked, isNotEmpty);
    expect(asked, everyElement(startsWith('vo:')));
    // It is the lines of this lesson's activities, all of them, not only the first.
    final List<String> expected = voiceLinesOf(<Map<String, Object?>>[
      for (final String id in content.lessons['butterflies']!.itemIds) content.activities[id]!.json,
    ]);
    expect(expected.length, greaterThan(3));
    expect(asked, expected);
  });

  testWidgets(
    'with a lazy narrator voice the lesson loads its part pack once, and the first question is spoken from it',
    (WidgetTester tester) async {
      final PackContent content = await loadStarter();
      final List<String> ids = voiceLinesOf(<Map<String, Object?>>[
        for (final String id in content.lessons['butterflies']!.itemIds) content.activities[id]!.json,
      ]);
      final PackKey key = await newTestKey();
      final VerifiedPack part = await verifyPack(
        (await buildVoicePack(key, 'nitzi', <String, List<(int, int)>>{
          for (final String id in ids) id.substring(3): <(int, int)>[(0, 0), (100, 1), (200, 0)],
        }, packId: 'voice-nitzi-part-num-a-1')).bytes,
        publicKey: key.publicKey,
      );
      final List<String> loads = <String>[];
      final LazyVoicePacks lazy = LazyVoicePacks(
        index: <String, String>{for (final String id in ids) id: 'voice-nitzi-part-num-a-1'},
        loader: (String packId) async {
          loads.add(packId);
          return part;
        },
      );
      final FakePlayer player = FakePlayer();
      final AppRig rig = AppRig(
        player: player,
        characters: _Source(await makeSource(), VoiceBank.lazy('nitzi', lazy)),
      );
      await rig.seedFinishedSetup();
      addTearDown(rig.db.close);
      expect(lazy.residentPacks, isEmpty);
      await pumpScreen(
        tester,
        ProviderScope(
          overrides: rig.overrides,
          child: const LessonScreen(profileId: child),
        ),
      );
      await _untilFrame(tester);
      for (int i = 0; i < 10 && player.plays == 0; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(loads, <String>['voice-nitzi-part-num-a-1'], reason: 'the pack is read once, not once per line');
      expect(lazy.residentPacks, <String>['voice-nitzi-part-num-a-1']);
      expect(player.plays, greaterThanOrEqualTo(1), reason: 'the first question is heard');
    },
  );
}
