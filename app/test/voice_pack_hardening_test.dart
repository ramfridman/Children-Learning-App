// B-45 review fixes: SEC-36 (a part of another version is not heard), SEC-37 (no character id with the part marker),
// QA-B45-1 (a pack is read and proven off the UI isolate, with the same results and errors) and QA-B45-2 (a part that failed
// for a passing reason is tried once more when a lesson opens, never in a loop).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const List<(int, int)> _cues = <(int, int)>[(0, 1), (100, 0)];
final String _sep = Platform.pathSeparator;

void main() {
  late PackKey key;
  late Directory dir;
  late Directory root;
  late AppDatabase db;
  late PackInstaller installer;
  late InstalledCharacterSource source;
  setUpAll(() async => key = await newTestKey());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nn_harden_');
    root = Directory('${dir.path}${_sep}packs');
    db = AppDatabase(NativeDatabase.memory());
    installer = PackInstaller(
      root: root,
      registry: DbPackRegistry(db),
      publicKey: key.publicKey,
      capabilities: AppCapabilities.current,
    );
    source = InstalledCharacterSource(installer: installer, bundledHouse: () async => Uint8List(0));
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> install(
    String character,
    String packId,
    List<String> lines, {
    String version = '2.0.0',
  }) async => installer.install(
    (await buildVoicePack(
      key,
      character,
      <String, List<(int, int)>>{for (final String l in lines) l: _cues},
      version: version,
      packId: packId,
    )).bytes,
  );

  File soundOf(String packId, String line, {String version = '2.0.0'}) =>
      File('${root.path}$_sep$packId$_sep$version${_sep}vo.$line.mp3');

  group('SEC-36: only the packs of the shared pack\'s version are heard', () {
    test('a part of an older version, left from an earlier layout, speaks nothing', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.greeting.hello']);
      await install('nitzi', 'voice-nitzi-part-x', <String>['old.pulled.line'], version: '1.0.0');
      await install('nitzi', 'voice-nitzi-part-y', <String>['b.numb03.1.prompt']);
      final VoiceBank bank = await source.voice('nitzi');
      expect(bank.has('vo:old.pulled.line'), isFalse);
      expect(await bank.fetch('vo:old.pulled.line'), isNull);
      expect(bank.has('vo:b.numb03.1.prompt'), isTrue);
      expect(bank.has('vo:core.greeting.hello'), isTrue);
    });

    test('a newer part than the shared pack is not heard either; without a shared pack the newest version counts', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.a'], version: '2.0.0');
      await install('nitzi', 'voice-nitzi-part-z', <String>['b.new.line'], version: '2.1.0');
      expect((await source.voice('nitzi')).has('vo:b.new.line'), isFalse);
      await install('hero-son', 'voice-hero-son-part-a', <String>['b.old.line'], version: '1.0.0');
      await install('hero-son', 'voice-hero-son-part-b', <String>['b.new.line'], version: '2.0.0');
      final VoiceBank hero = await source.voice('hero-son');
      expect(hero.has('vo:b.new.line'), isTrue);
      expect(hero.has('vo:b.old.line'), isFalse);
    });
  });

  group('SEC-37: a character id never holds the part marker', () {
    List<String> idProblems(String id) => <String>[
      for (final Problem p in validate(characterSchema, <String, Object?>{'id': id}))
        if (p.path == 'id') p.message,
    ];

    test('the character schema refuses it, and accepts the ids that are used', () {
      expect(idProblems('hero-part-two'), isNotEmpty);
      expect(idProblems('x-part-y'), isNotEmpty);
      for (final String ok in <String>[
        'nitzi',
        'hero-son',
        'friend-daughter',
        'party-hat',
        'depart-ure',
        'part-one',
      ]) {
        expect(idProblems(ok), isEmpty, reason: ok);
      }
    });

    test('so does the list of characters in a manifest', () {
      final RegExp pattern = RegExp('^(?:${Patterns.characterId})\$');
      expect(pattern.hasMatch('hero-part-two'), isFalse);
      expect(pattern.hasMatch('hero-son'), isTrue);
    });
  });

  group('QA-B45-1: a pack is read and proven off the UI isolate, with the same results', () {
    // A decode that is not `jsonDecode` itself is done here, on this isolate: the way the answer is compared.
    PackInstaller here() => PackInstaller(
      root: root,
      registry: DbPackRegistry(db),
      publicKey: key.publicKey,
      capabilities: AppCapabilities.current,
      decode: (String text) => jsonDecode(text),
    );

    test('the pack is the same, byte for byte, as the one proven here', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.a', 'core.b']);
      final VerifiedPack off = (await installer.load('voice-nitzi'))!;
      final VerifiedPack inline = (await here().load('voice-nitzi'))!;
      expect(off.manifestSha256, inline.manifestSha256);
      expect(off.id, inline.id);
      expect(off.version, inline.version);
      expect(off.hidden, inline.hidden);
      expect(off.manifestBytes, inline.manifestBytes);
      expect(off.signature, inline.signature);
      expect(off.files.keys.toSet(), inline.files.keys.toSet());
      for (final String name in off.files.keys) {
        expect(off.files[name], inline.files[name], reason: name);
      }
      expect(jsonEncode(off.docs), jsonEncode(inline.docs));
      expect(jsonEncode(off.manifest), jsonEncode(inline.manifest));
    });

    test(
      'the errors are the same: a changed file, a changed signature, a missing folder, a stray folder',
      () async {
        await install('nitzi', 'voice-nitzi', <String>['core.a']);
        Future<List<String>> failure(PackInstaller i) async {
          try {
            await i.load('voice-nitzi');
            return <String>['no error'];
          } on PackRejected catch (e) {
            return <String>[e.stage, e.reason, ...e.problems.map((Problem p) => p.toString())];
          }
        }

        final File sound = soundOf('voice-nitzi', 'core.a');
        final Uint8List good = sound.readAsBytesSync();
        sound.writeAsBytesSync(<int>[...good, 1]);
        expect((await failure(installer)).first, 'files');
        expect(await failure(installer), await failure(here()));
        sound.writeAsBytesSync(good);

        final File sig = File('${root.path}${_sep}voice-nitzi$_sep${'2.0.0'}${_sep}manifest.sig');
        final Uint8List goodSig = sig.readAsBytesSync();
        sig.writeAsBytesSync(Uint8List.fromList(goodSig)..[3] ^= 1);
        expect((await failure(installer)).first, 'signature');
        expect(await failure(installer), await failure(here()));
        sig.writeAsBytesSync(goodSig);

        Directory('${root.path}${_sep}voice-nitzi$_sep${'2.0.0'}${_sep}stray').createSync();
        expect(await failure(installer), <String>[
          'disk',
          'the installed pack holds something that is not a file',
        ]);
        expect(await failure(installer), await failure(here()));
        Directory('${root.path}${_sep}voice-nitzi$_sep${'2.0.0'}${_sep}stray').deleteSync();

        Directory('${root.path}${_sep}voice-nitzi').renameSync('${root.path}${_sep}elsewhere');
        expect((await failure(installer)).first, 'disk');
        expect(await failure(installer), await failure(here()));
        Directory('${root.path}${_sep}elsewhere').renameSync('${root.path}${_sep}voice-nitzi');
        expect(await failure(installer), <String>['no error']);
      },
    );

    test('the installed copy of a pack that is installed again is proven the same way', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.a']);
      final Uint8List bytes = (await buildVoicePack(
        key,
        'nitzi',
        <String, List<(int, int)>>{'core.a': _cues},
        version: '2.0.0',
        packId: 'voice-nitzi',
      )).bytes;
      expect((await installer.install(bytes)).outcome, InstallOutcome.alreadyInstalled);
    });
  });

  group('QA-B45-2: a part that failed for a passing reason is tried once more, when a lesson opens', () {
    test(
      'a pack that was not readable is loaded by the next prefetch, once, and not by another line',
      () async {
        await install('nitzi', 'voice-nitzi', <String>['core.a']);
        await install('nitzi', 'voice-nitzi-part-a', <String>['a.1.prompt']);
        final VoiceBank bank = await source.voice('nitzi');
        final Directory part = Directory('${root.path}${_sep}voice-nitzi-part-a');
        part.renameSync('${root.path}${_sep}away');
        expect(await bank.fetch('vo:a.1.prompt'), isNull, reason: 'the files were not there');
        expect(bank.has('vo:a.1.prompt'), isFalse);
        Directory('${root.path}${_sep}away').renameSync(part.path);
        expect(await bank.fetch('vo:a.1.prompt'), isNull, reason: 'a line never makes it try again');
        await bank.prefetch(<String>['vo:a.1.prompt']);
        expect(bank.has('vo:a.1.prompt'), isTrue);
        expect(utf8.decode((await bank.fetch('vo:a.1.prompt'))!.mp3), 'mp3:nitzi:a.1.prompt');
      },
    );

    test('a pack that fails again on its one more try stays silent, however many lessons open', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.a']);
      await install('nitzi', 'voice-nitzi-part-a', <String>['a.1.prompt']);
      final VoiceBank bank = await source.voice('nitzi');
      final Directory part = Directory('${root.path}${_sep}voice-nitzi-part-a');
      part.renameSync('${root.path}${_sep}away');
      await bank.fetch('vo:a.1.prompt');
      await bank.prefetch(<String>['vo:a.1.prompt']);
      Directory('${root.path}${_sep}away').renameSync(part.path);
      await bank.prefetch(<String>['vo:a.1.prompt']);
      await bank.prefetch(<String>['vo:a.1.prompt']);
      expect(bank.has('vo:a.1.prompt'), isFalse, reason: 'one retry, and it failed');
      expect(await bank.fetch('vo:a.1.prompt'), isNull);
    });

    test(
      'a pack that failed its signature or hash check stays given up, even when the file is mended',
      () async {
        await install('nitzi', 'voice-nitzi', <String>['core.a']);
        await install('nitzi', 'voice-nitzi-part-a', <String>['a.1.prompt']);
        final VoiceBank bank = await source.voice('nitzi');
        final File sound = soundOf('voice-nitzi-part-a', 'a.1.prompt');
        final Uint8List good = sound.readAsBytesSync();
        sound.writeAsBytesSync(<int>[...good, 1]);
        expect(await bank.fetch('vo:a.1.prompt'), isNull);
        sound.writeAsBytesSync(good);
        await bank.prefetch(<String>['vo:a.1.prompt']);
        expect(bank.has('vo:a.1.prompt'), isFalse);
        expect(await bank.fetch('vo:a.1.prompt'), isNull);
        expect(bank.packs!.failedPacks, <String>{'voice-nitzi-part-a'});
      },
    );
  });

  group('QA-B45-2 in the lazy store: what is retried and what is not', () {
    late VerifiedPack pack;
    setUpAll(() async {
      pack = await verifyPack(
        (await buildVoicePack(key, 'nitzi', <String, List<(int, int)>>{
          'a.1.prompt': _cues,
        }, packId: 'voice-nitzi-part-a')).bytes,
        publicKey: key.publicKey,
      );
    });

    ({LazyVoicePacks store, List<String> calls}) store(Future<VerifiedPack?> Function(int call) answer) {
      final List<String> calls = <String>[];
      return (
        calls: calls,
        store: LazyVoicePacks(
          index: const <String, String>{'vo:a.1.prompt': 'voice-nitzi-part-a'},
          loader: (String id) {
            calls.add(id);
            return answer(calls.length);
          },
        ),
      );
    }

    test(
      'a loader that throws something else, or says it may pass, is tried once more by a prefetch only',
      () async {
        for (final Object error in <Object>[
          StateError('disk'),
          const VoicePackUnavailable(permanent: false),
        ]) {
          final s = store((int call) async => call == 1 ? throw error : pack);
          expect(await s.store.fetch('vo:a.1.prompt'), isNull);
          expect(await s.store.fetch('vo:a.1.prompt'), isNull);
          expect(s.calls.length, 1, reason: 'no loop: $error');
          await s.store.prefetch(<String>['vo:a.1.prompt']);
          expect(s.calls.length, 2);
          expect(s.store.knows('vo:a.1.prompt'), isTrue);
          expect(await s.store.fetch('vo:a.1.prompt'), isNotNull);
        }
      },
    );

    test('a second failure is final', () async {
      final s = store((int call) async => throw StateError('disk'));
      await s.store.fetch('vo:a.1.prompt');
      await s.store.prefetch(<String>['vo:a.1.prompt']);
      await s.store.prefetch(<String>['vo:a.1.prompt']);
      await s.store.prefetch(<String>['vo:a.1.prompt']);
      expect(s.calls.length, 2);
      expect(s.store.knows('vo:a.1.prompt'), isFalse);
    });

    test('a permanent refusal, or a loader that has nothing, is never tried again', () async {
      final refused = store((int call) async => throw const VoicePackUnavailable(permanent: true));
      await refused.store.fetch('vo:a.1.prompt');
      await refused.store.prefetch(<String>['vo:a.1.prompt']);
      expect(refused.calls.length, 1);
      final nothing = store((int call) async => null);
      await nothing.store.fetch('vo:a.1.prompt');
      await nothing.store.prefetch(<String>['vo:a.1.prompt']);
      expect(nothing.calls.length, 1);
    });

    test('the shared pack is tried once more too', () async {
      final List<String> calls = <String>[];
      final LazyVoicePacks s = LazyVoicePacks(
        index: const <String, String>{'vo:a.1.prompt': 'voice-nitzi'},
        pinned: const <String>{'voice-nitzi'},
        loader: (String id) async {
          calls.add(id);
          return calls.length == 1 ? throw StateError('disk') : pack;
        },
      );
      await s.loadPinned();
      expect(s.knows('vo:a.1.prompt'), isFalse);
      await s.prefetch(<String>['vo:a.1.prompt']);
      expect(calls.length, 2);
      expect(s.peek('vo:a.1.prompt'), isNotNull);
      expect(s.residentPacks, <String>['voice-nitzi']);
    });
  });
}
