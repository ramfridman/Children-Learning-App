// B-45: a narrator's voice is about sixteen packs, read one at a time. The shared pack stays in memory, at most two part packs
// are in memory at once (the one used longest ago makes room), a pack that fails is a missing clip, and the voice director
// waits for a pack to load without ever saying a late line. All with fake loaders and mock packs.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/voice/voice_lines.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const List<(int, int)> _cues = <(int, int)>[(0, 1), (100, 0)];

void main() {
  late PackKey key;
  late Map<String, VerifiedPack> packs;
  setUpAll(() async {
    key = await newTestKey();
    Future<VerifiedPack> make(String character, String packId, List<String> lines) async => verifyPack(
      (await buildVoicePack(key, character, <String, List<(int, int)>>{
        for (final String l in lines) l: _cues,
      }, packId: packId)).bytes,
      publicKey: key.publicKey,
    );
    packs = <String, VerifiedPack>{
      'voice-nitzi': await make('nitzi', 'voice-nitzi', <String>['core.greeting.hello', 'fb.ord']),
      'voice-nitzi-part-a': await make('nitzi', 'voice-nitzi-part-a', <String>['a.1.prompt', 'a.2.prompt']),
      'voice-nitzi-part-b': await make('nitzi', 'voice-nitzi-part-b', <String>['b.1.prompt']),
      'voice-nitzi-part-c': await make('nitzi', 'voice-nitzi-part-c', <String>['c.1.prompt']),
      'voice-nitzi-part-d': await make('nitzi', 'voice-nitzi-part-d', <String>['d.1.prompt']),
    };
  });

  /// A lazy store over the mock packs that counts its loads; [hold] makes a load wait until it is completed.
  ({LazyVoicePacks store, List<String> loads, Map<String, Completer<void>> hold}) lazy({
    int maxParts = 2,
    Set<String> failing = const <String>{},
    Set<String> throwing = const <String>{},
  }) {
    final List<String> loads = <String>[];
    final Map<String, Completer<void>> hold = <String, Completer<void>>{};
    final Map<String, String> index = <String, String>{
      for (final VerifiedPack p in packs.values)
        for (final Object? v in p.manifest['vo']! as List<Object?>)
          'vo:${(v! as Map<String, Object?>)['id']}': p.id,
    };
    final LazyVoicePacks store = LazyVoicePacks(
      index: index,
      pinned: const <String>{'voice-nitzi'},
      maxParts: maxParts,
      loader: (String id) async {
        loads.add(id);
        await hold[id]?.future;
        if (throwing.contains(id)) throw StateError('disk');
        return failing.contains(id) ? null : packs[id];
      },
    );
    return (store: store, loads: loads, hold: hold);
  }

  String said(VoiceClip? c) => utf8.decode(c!.mp3);

  group('the lookup across packs', () {
    test('finds a line in whichever pack holds it, and says nothing for a line no pack holds', () async {
      final store = lazy().store;
      expect(said(await store.fetch('vo:core.greeting.hello')), 'mp3:nitzi:core.greeting.hello');
      expect(said(await store.fetch('vo:b.1.prompt')), 'mp3:nitzi:b.1.prompt');
      expect(said(await store.fetch('vo:a.2.prompt')), 'mp3:nitzi:a.2.prompt');
      expect(await store.fetch('vo:no.such.line'), isNull);
      expect(store.knows('vo:c.1.prompt'), isTrue);
      expect(store.knows('vo:no.such.line'), isFalse);
    });

    test('a bank lists and knows every line of every pack before any is loaded', () {
      final VoiceBank bank = VoiceBank.lazy('nitzi', lazy().store);
      expect(bank.length, 7);
      expect(bank.ids.toSet(), contains('vo:d.1.prompt'));
      expect(bank.has('vo:d.1.prompt'), isTrue);
      expect(bank.clip('vo:d.1.prompt'), isNull, reason: 'only what is in memory');
      expect(bank.canLoad('vo:d.1.prompt'), isTrue);
      expect(bank.canLoad('vo:no.such.line'), isFalse);
    });
  });

  group('loading a pack when a line first needs it', () {
    test('nothing is loaded at first, the shared pack is loaded on request, a part only when one of its lines is wanted', () async {
      final r = lazy();
      expect(r.loads, isEmpty);
      expect(r.store.residentPacks, isEmpty);
      await r.store.loadPinned();
      expect(r.loads, <String>['voice-nitzi']);
      expect(r.store.peek('vo:fb.ord'), isNotNull);
      expect(r.store.peek('vo:a.1.prompt'), isNull);
      await r.store.fetch('vo:a.1.prompt');
      expect(r.loads, <String>['voice-nitzi', 'voice-nitzi-part-a']);
      expect(r.store.peek('vo:a.2.prompt'), isNotNull, reason: 'the whole pack came in');
      await r.store.fetch('vo:a.2.prompt');
      expect(r.loads.length, 2, reason: 'a pack in memory is not loaded again');
    });

    test('two lines of one pack wanted at the same moment load the pack once', () async {
      final r = lazy();
      r.hold['voice-nitzi-part-a'] = Completer<void>();
      final Future<VoiceClip?> one = r.store.fetch('vo:a.1.prompt');
      final Future<VoiceClip?> two = r.store.fetch('vo:a.2.prompt');
      r.hold['voice-nitzi-part-a']!.complete();
      expect(said(await one), 'mp3:nitzi:a.1.prompt');
      expect(said(await two), 'mp3:nitzi:a.2.prompt');
      expect(r.loads, <String>['voice-nitzi-part-a']);
    });

    test(
      'a lesson prefetches the packs of its first lines, at most two parts, and not the shared pack',
      () async {
        final r = lazy();
        await r.store.prefetch(<String>[
          'vo:core.greeting.hello',
          'vo:b.1.prompt',
          'vo:b.1.prompt',
          'vo:c.1.prompt',
          'vo:d.1.prompt',
        ]);
        expect(r.loads, <String>['voice-nitzi-part-b', 'voice-nitzi-part-c']);
        expect(r.store.residentPacks, <String>['voice-nitzi-part-b', 'voice-nitzi-part-c']);
        await r.store.prefetch(<String>['vo:b.1.prompt']);
        expect(r.loads.length, 2);
      },
    );
  });

  group('the memory bound', () {
    test(
      'the shared pack stays, and at most two parts are in memory: the one used longest ago goes first',
      () async {
        final r = lazy();
        await r.store.loadPinned();
        await r.store.fetch('vo:a.1.prompt');
        await r.store.fetch('vo:b.1.prompt');
        expect(r.store.residentPacks, <String>['voice-nitzi', 'voice-nitzi-part-a', 'voice-nitzi-part-b']);
        await r.store.fetch('vo:c.1.prompt');
        expect(r.store.residentPacks, <String>[
          'voice-nitzi',
          'voice-nitzi-part-b',
          'voice-nitzi-part-c',
        ], reason: 'a, the oldest, went');
        expect(r.store.peek('vo:a.1.prompt'), isNull);
        expect(r.store.canLoad('vo:a.1.prompt'), isTrue);
        // Using b makes c the oldest.
        expect(r.store.peek('vo:b.1.prompt'), isNotNull);
        await r.store.fetch('vo:d.1.prompt');
        expect(r.store.residentPacks, <String>['voice-nitzi', 'voice-nitzi-part-b', 'voice-nitzi-part-d']);
        // A pack that went is loaded again when wanted.
        await r.store.fetch('vo:a.1.prompt');
        expect(r.loads.where((String l) => l == 'voice-nitzi-part-a').length, 2);
        expect(
          r.loads.where((String l) => l == 'voice-nitzi').length,
          1,
          reason: 'the shared pack was never let go',
        );
      },
    );

    test(
      'a room is made before the load, so the loading pack and the resident parts never exceed the bound',
      () async {
        final r = lazy();
        await r.store.fetch('vo:a.1.prompt');
        await r.store.fetch('vo:b.1.prompt');
        r.hold['voice-nitzi-part-c'] = Completer<void>();
        final Future<VoiceClip?> loading = r.store.fetch('vo:c.1.prompt');
        await Future<void>.delayed(Duration.zero);
        expect(r.store.residentPacks.length, 1, reason: 'one part was let go for the pack that is coming');
        r.hold['voice-nitzi-part-c']!.complete();
        await loading;
        expect(r.store.residentPacks.length, 2);
      },
    );

    test('with several packs loading at once the bound still holds', () async {
      final r = lazy();
      await Future.wait(<Future<VoiceClip?>>[
        r.store.fetch('vo:a.1.prompt'),
        r.store.fetch('vo:b.1.prompt'),
        r.store.fetch('vo:c.1.prompt'),
        r.store.fetch('vo:d.1.prompt'),
      ]);
      expect(r.store.residentPacks.length, lessThanOrEqualTo(2));
    });
  });

  group('a pack that cannot be loaded', () {
    test(
      'is a missing clip: null, no longer claimed, not asked for again, and the other packs go on',
      () async {
        final r = lazy(failing: <String>{'voice-nitzi-part-b'});
        expect(await r.store.fetch('vo:b.1.prompt'), isNull);
        expect(r.store.failedPacks, <String>{'voice-nitzi-part-b'});
        expect(r.store.knows('vo:b.1.prompt'), isFalse);
        expect(r.store.canLoad('vo:b.1.prompt'), isFalse);
        expect(await r.store.fetch('vo:b.1.prompt'), isNull);
        expect(r.loads, <String>['voice-nitzi-part-b']);
        expect(said(await r.store.fetch('vo:a.1.prompt')), 'mp3:nitzi:a.1.prompt');
      },
    );

    test('a pack that throws is the same, and the error goes nowhere', () async {
      final r = lazy(throwing: <String>{'voice-nitzi-part-c'});
      expect(await r.store.fetch('vo:c.1.prompt'), isNull);
      expect(r.store.failedPacks, <String>{'voice-nitzi-part-c'});
      final VoiceBank bank = VoiceBank.lazy('nitzi', r.store);
      expect(bank.has('vo:c.1.prompt'), isFalse);
      expect(bank.canLoad('vo:c.1.prompt'), isFalse);
      expect(await bank.fetch('vo:c.1.prompt'), isNull);
    });
  });

  group('the narrator behind a friend', () {
    late VoiceBank friend;
    setUpAll(() async {
      friend = VoiceBank.fromPack(
        await verifyPack(
          (await buildVoicePack(key, 'tower-tamir', <String, List<(int, int)>>{
            'core.greeting.hello': _cues,
          })).bytes,
          publicKey: key.publicKey,
        ),
      );
    });

    test('the friend\'s own line is the friend\'s, at once; every other line is the narrator\'s, once its pack is loaded', () async {
      final r = lazy();
      await r.store.loadPinned();
      final VoiceBank guide = VoiceBank.withFallback(friend, VoiceBank.lazy('nitzi', r.store));
      expect(said(guide.clip('vo:core.greeting.hello')), 'mp3:tower-tamir:core.greeting.hello');
      expect(guide.canLoad('vo:core.greeting.hello'), isFalse);
      expect(
        said(guide.clip('vo:fb.ord')),
        'mp3:nitzi:fb.ord',
        reason: 'the narrator\'s shared lines are in memory',
      );
      expect(guide.clip('vo:a.1.prompt'), isNull);
      expect(guide.canLoad('vo:a.1.prompt'), isTrue);
      expect(said(await guide.fetch('vo:a.1.prompt')), 'mp3:nitzi:a.1.prompt');
      expect(said(guide.clip('vo:a.1.prompt')), 'mp3:nitzi:a.1.prompt');
      expect(guide.has('vo:d.1.prompt'), isTrue);
      expect(guide.characterId, 'tower-tamir');
    });

    test(
      'a narrator pack that fails leaves the line silent, as a line the narrator never recorded',
      () async {
        final r = lazy(failing: <String>{'voice-nitzi-part-a'});
        final VoiceBank guide = VoiceBank.withFallback(friend, VoiceBank.lazy('nitzi', r.store));
        expect(await guide.fetch('vo:a.1.prompt'), isNull);
        expect(guide.has('vo:a.1.prompt'), isFalse);
        expect(guide.canLoad('vo:a.1.prompt'), isFalse);
        expect(await guide.fetch('vo:no.such.line'), isNull);
      },
    );

    test('a lesson prefetch reaches the narrator\'s packs behind a friend', () async {
      final r = lazy();
      final VoiceBank guide = VoiceBank.withFallback(friend, VoiceBank.lazy('nitzi', r.store));
      await guide.prefetch(<String>['vo:c.1.prompt']);
      expect(r.loads, <String>['voice-nitzi-part-c']);
    });
  });

  group('the voice director with a lazy voice', () {
    late FakePlayer player;
    late VoiceDirector director;
    late ({LazyVoicePacks store, List<String> loads, Map<String, Completer<void>> hold}) r;

    Future<void> settle() async {
      for (int i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    setUp(() async {
      player = FakePlayer();
      director = VoiceDirector(player: player);
      r = lazy();
      await r.store.loadPinned();
      director.useBank(VoiceBank.lazy('nitzi', r.store));
    });
    tearDown(() async {
      director.dispose();
    });

    test('a line in memory is said as before, with nothing awaited', () async {
      final Future<void> done = director.say('vo:fb.ord');
      await done;
      expect(player.plays, 1);
    });

    test('a line whose pack is not loaded is loaded and then said', () async {
      r.hold['voice-nitzi-part-a'] = Completer<void>();
      final Future<void> done = director.say('vo:a.1.prompt');
      await settle();
      expect(player.plays, 0, reason: 'the pack is still coming');
      r.hold['voice-nitzi-part-a']!.complete();
      await done;
      expect(player.plays, 1);
      expect(utf8.decode(player.played.single), 'mp3:nitzi:a.1.prompt');
    });

    test('a prefetch before the first line leaves nothing to wait for', () async {
      await director.prefetch(<String>['vo:a.1.prompt']);
      expect(r.loads, <String>['voice-nitzi', 'voice-nitzi-part-a']);
      final Future<void> done = director.say('vo:a.1.prompt');
      await done;
      expect(player.plays, 1);
      expect(r.loads.length, 2);
    });

    test('a line that was waiting for its pack is not said if another line replaced it, or the voice was stopped', () async {
      r.hold['voice-nitzi-part-a'] = Completer<void>();
      final Future<void> lateOne = director.say('vo:a.1.prompt');
      await director.say('vo:fb.ord');
      expect(player.plays, 1);
      r.hold['voice-nitzi-part-a']!.complete();
      await lateOne;
      expect(player.plays, 1, reason: 'the line that replaced it is not cut off by the late one');

      r.hold['voice-nitzi-part-b'] = Completer<void>();
      final Future<void> stopped = director.say('vo:b.1.prompt');
      await director.stop();
      r.hold['voice-nitzi-part-b']!.complete();
      await stopped;
      expect(player.plays, 1);
    });

    test('a line is not said late when it is no longer relevant, or when its screen has closed', () async {
      final Object screen = Object();
      final Object other = Object();
      r.hold['voice-nitzi-part-a'] = Completer<void>();
      bool relevant = true;
      final Future<void> a = director.say('vo:a.1.prompt', owner: screen, relevant: () => relevant);
      relevant = false;
      r.hold['voice-nitzi-part-a']!.complete();
      await a;
      expect(player.plays, 0);

      r.hold['voice-nitzi-part-b'] = Completer<void>();
      final Future<void> b = director.sayNext('vo:b.1.prompt', owner: screen);
      await director.stopFor(screen);
      r.hold['voice-nitzi-part-b']!.complete();
      await b;
      expect(player.plays, 0);

      // Another screen's line, loading at the same moment, is not lost with it.
      r.hold['voice-nitzi-part-c'] = Completer<void>();
      final Future<void> mine = director.sayNext('vo:c.1.prompt', owner: other);
      await director.stopFor(screen);
      r.hold['voice-nitzi-part-c']!.complete();
      await mine;
      expect(player.plays, 1);
    });

    test('sayNext waits for its pack and then joins the queue behind the line that is playing', () async {
      await director.say('vo:fb.ord');
      expect(player.plays, 1);
      r.hold['voice-nitzi-part-a'] = Completer<void>();
      final Future<void> next = director.sayNext('vo:a.1.prompt');
      r.hold['voice-nitzi-part-a']!.complete();
      await next;
      expect(player.plays, 1, reason: 'it waits for the line that is playing');
      player.finish();
      await settle();
      expect(player.plays, 2);
    });

    test(
      'a pack that fails is a silent line: nothing plays, nothing breaks, and the next line goes on',
      () async {
        final r2 = lazy(failing: <String>{'voice-nitzi-part-a'});
        await r2.store.loadPinned();
        director.useBank(VoiceBank.lazy('nitzi', r2.store));
        await director.say('vo:a.1.prompt');
        await director.sayNext('vo:a.2.prompt');
        expect(player.plays, 0);
        await director.say('vo:fb.ord');
        expect(player.plays, 1);
      },
    );
  });

  test('the lines a document asks for are listed in order, once each', () {
    expect(
      voiceLinesOf(<Map<String, Object?>>[
        <String, Object?>{
          'prompt': <String, Object?>{'vo': 'vo:x.1.prompt', 'caption': 'שלום'},
          'hints': <Object?>[
            <String, Object?>{'vo': 'vo:x.1.h1'},
            <String, Object?>{'vo': 'vo:x.1.h2'},
          ],
          'again': 'vo:x.1.prompt',
          'note': 'not a line',
        },
        <String, Object?>{'vo': 'vo:y.1.prompt'},
      ]),
      <String>['vo:x.1.prompt', 'vo:x.1.h1', 'vo:x.1.h2', 'vo:y.1.prompt'],
    );
  });
}
