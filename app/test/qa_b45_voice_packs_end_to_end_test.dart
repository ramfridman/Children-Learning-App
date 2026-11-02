@Timeout(Duration(minutes: 10))
library;

// QA (B-45): the whole chain for the real planned ids with mock clips and a throw-away key: build the packs of a narrator and of
// a friend, check each one the way the app does (verifyPack under ZipLimits), install them with the real installer, and play
// through the lookups of the lazy bank. No network, no ElevenLabs, no real key.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/voice/voice_lines.dart';
import 'package:nitznutz/voice/voice_pack_ids.dart';
import 'package:nitznutz/world/world_state.dart';

import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

Map<String, Object?> _config() =>
    jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;

/// A short plain Hebrew text that no other line has (the spoken texts of the real run need the master table; this test is about
/// packs, not wording): "שלום" and the index in the letters א to י.
String _text(int i) =>
    'שלום ${i.toString().split('').map((String d) => String.fromCharCode(0x05D0 + int.parse(d))).join()}.';

/// The 4,166 planned lines of a narrator (3,991 at the QA of 2026-11-02, +27 core lines the app asks for, +48 welcome, +100 map cards): every voice id of the starter content and of the core lines.
final List<SpokenLine> _planned = <SpokenLine>[
  for (final (int i, String id) in <String>{
    for (final SpokenLine l in linesOfContent(Directory('../content/starter'))) l.voId,
    for (final SpokenLine l in coreLines(File('../content/lines/core.he.json'))) l.voId,
  }.toList().indexed)
    SpokenLine(id, _text(i)),
];

/// A clip that says whose it is: `<tag>|<text>`, padded to [pad] bytes.
class _Tagged implements Synthesizer {
  _Tagged(this.tag, {this.pad = 0});

  final String tag;
  final int pad;

  @override
  Future<Synthesis> say(ClipRequest request) async {
    final List<int> head = utf8.encode('$tag|${request.text}');
    final Uint8List bytes = Uint8List(head.length < pad ? pad : head.length)..setRange(0, head.length, head);
    return Synthesis(bytes, 'mp3', const Alignment(<String>['ש', 'ל'], <double>[0, 0.1], <double>[0.1, 0.2]));
  }
}

void _drop(Directory d) {
  for (final FileSystemEntity e in <FileSystemEntity>[d, File('${d.path}.voiced.jsonl')]) {
    try {
      e.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}

String _land(String packId) => packId.replaceFirst('voice-nitzi-part-', '');

void main() {
  // Two in-memory registries at once (the full install and a small one) are two separate databases on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PackKey key;
  late Directory scratch;
  late List<BuiltPack> nitzi;
  late List<BuiltPack> gali;
  late Map<String, String> textOf;

  setUpAll(() async {
    key = await newTestKey();
    scratch = Directory.systemTemp.createTempSync('nn_qa_b45_');
    textOf = <String, String>{for (final SpokenLine l in _planned) l.voId: l.text};
    nitzi = await generateVoicePack(
      characterId: 'nitzi',
      lines: _planned,
      synth: _Tagged('nitzi'),
      profile: VoiceProfile.fromConfig(_config(), 'nitzi'),
      key: key,
      workDir: Directory('${scratch.path}/nitzi'),
      version: '2.0.0',
    );
    gali = await generateVoicePack(
      characterId: 'inventor-gali',
      lines: _planned,
      synth: _Tagged('gali'),
      profile: VoiceProfile.fromConfig(_config(), 'inventor-gali'),
      key: key,
      workDir: Directory('${scratch.path}/gali'),
      version: '2.0.0',
    );
  });

  tearDownAll(() {
    _drop(Directory('${scratch.path}/nitzi'));
    _drop(Directory('${scratch.path}/gali'));
    _drop(scratch);
  });

  test('the planned ids are the 4,166 lines of the plan', () {
    expect(_planned.map((SpokenLine l) => l.voId).toSet().length, 4166);
  });

  test('a narrator is 18 packs (core, 15 land-and-band parts, welcome and skill) and a friend one; each passes verifyPack, under ZipLimits and under the 40 MiB / 3,000 limits', () async {
    expect(nitzi.length, 18);
    expect(gali.length, 1);
    expect(gali.single.fileName, 'voice-inventor-gali-2.0.0.nnpack');
    expect(nitzi.first.fileName, 'voice-nitzi-2.0.0.nnpack');
    final Set<String> seen = <String>{};
    int ids = 0;
    for (final BuiltPack b in nitzi) {
      final VerifiedPack p = await verifyPack(b.bytes, publicKey: key.publicKey);
      expect(p.version, '2.0.0');
      expect(p.hidden, isFalse);
      expect(isVoicePackOf('nitzi', p.id), isTrue);
      expect(b.fileName, '${p.id}-2.0.0.nnpack');
      final int entries = readStoredZip(b.bytes).length;
      expect(entries, lessThanOrEqualTo(VoicePackLimits.maxEntries), reason: p.id);
      expect(entries, lessThan(ZipLimits.maxEntries), reason: p.id);
      expect(b.bytes.length, lessThanOrEqualTo(VoicePackLimits.maxBytes), reason: p.id);
      expect(b.bytes.length, lessThan(ZipLimits.maxTotalBytes), reason: p.id);
      for (final Object? v in p.manifest['vo']! as List<Object?>) {
        final String id = (v! as Map<String, Object?>)['id']! as String;
        expect(seen.add('vo:$id'), isTrue, reason: '$id is in two packs');
        // The pack a line is in is the pack its group says.
        expect(
          p.id,
          voiceGroupOf(id) == 'core' ? 'voice-nitzi' : startsWith('voice-nitzi-part-${voiceGroupOf(id)}'),
          reason: id,
        );
        ids++;
      }
    }
    expect(ids, 4166);
    expect(seen, <String>{
      for (final SpokenLine l in _planned) l.voId,
    }, reason: 'every planned id is in exactly one pack');
    final VerifiedPack friend = await verifyPack(gali.single.bytes, publicKey: key.publicKey);
    expect((friend.manifest['vo']! as List<Object?>).length, 57);
    // A different key does not verify any of them.
    final PackKey other = await newTestKey();
    await expectLater(verifyPack(nitzi[3].bytes, publicKey: other.publicKey), throwsA(isA<PackRejected>()));
  });

  // The real installer, a real folder and a real (in-memory) registry. The full install of 17 packs is made once and only read;
  // a test that damages a pack installs just the three packs it needs into a folder of its own.
  late _Phone full;

  setUpAll(() async {
    full = await _Phone.open(key, <BuiltPack>[...nitzi, ...gali]);
  });
  tearDownAll(() => full.close());

  group('installed with the real installer', () {
    late Directory root;
    late InstalledCharacterSource source;
    late _Phone small;

    setUp(() {
      root = full.root;
      source = full.source;
    });

    Future<void> smallPhone() async {
      const Set<String> files = <String>{
        'voice-nitzi-2.0.0.nnpack',
        'voice-nitzi-part-col-a-2.0.0.nnpack',
        'voice-nitzi-part-log-a-2.0.0.nnpack',
        'voice-inventor-gali-2.0.0.nnpack',
      };
      small = await _Phone.open(key, <BuiltPack>[
        for (final BuiltPack b in <BuiltPack>[...nitzi, ...gali])
          if (files.contains(b.fileName)) b,
      ]);
      addTearDown(small.close);
      root = small.root;
      source = small.source;
    }

    String firstOf(String group) =>
        _planned.map((SpokenLine l) => l.voId).firstWhere((String id) => voiceGroupOf(id) == group);

    File soundOf(String packId, String voId) => File(
      '${root.path}${Platform.pathSeparator}$packId${Platform.pathSeparator}2.0.0${Platform.pathSeparator}vo.${voId.substring(3)}.mp3',
    );

    test(
      'the index knows all 4,166 lines before any part is read; only the shared pack is in memory',
      () async {
        final VoiceBank bank = await source.voice('nitzi');
        expect(bank.length, 4166);
        expect(bank.packs!.residentPacks, <String>['voice-nitzi']);
        expect(bank.packs!.failedPacks, isEmpty);
        for (final SpokenLine l in _planned) {
          expect(bank.has(l.voId), isTrue, reason: l.voId);
        }
      },
    );

    test('a line from each of the 17 parts (15 land-and-band, welcome and skill), and a core line, is found and is that line\'s own sound', () async {
      final VoiceBank bank = await source.voice('nitzi');
      final String core = firstOf('core');
      expect(
        utf8.decode(bank.clip(core)!.mp3),
        'nitzi|${textOf[core]}',
        reason: 'the shared pack is already in memory',
      );
      final List<String> parts = <String>[
        for (final BuiltPack b in nitzi.skip(1)) b.fileName.replaceFirst('-2.0.0.nnpack', ''),
      ];
      expect(parts.length, 17);
      int visited = 0;
      for (final String packId in parts) {
        final String group = _land(packId);
        final String id = _planned
            .map((SpokenLine l) => l.voId)
            .firstWhere((String v) => bank.packs!.index[v] == packId, orElse: () => '');
        expect(id, isNotEmpty, reason: packId);
        expect(voiceGroupOf(id), isNot('core'), reason: group);
        expect(bank.canLoad(id), isTrue, reason: 'not read yet: $id');
        expect(bank.clip(id), isNull);
        final VoiceClip? clip = await bank.fetch(id);
        expect(clip, isNotNull, reason: packId);
        expect(utf8.decode(clip!.mp3), 'nitzi|${textOf[id]}', reason: id);
        expect(clip.mouth.length, greaterThan(0), reason: '$id has its mouth cues');
        expect(bank.packs!.residentPacks.length, lessThanOrEqualTo(3), reason: 'pinned + at most 2 parts');
        expect(bank.packs!.residentPacks.last, packId);
        expect(
          bank.packs!.residentPacks.first,
          'voice-nitzi',
          reason: 'the shared pack was never pushed out',
        );
        visited++;
      }
      expect(visited, 17);
      expect(bank.packs!.failedPacks, isEmpty);
    });

    test(
      'three lands visited: the first is let go, the shared pack stays, and going back loads it again',
      () async {
        final VoiceBank bank = await source.voice('nitzi');
        final LazyVoicePacks lazy = bank.packs!;
        final String col = firstOf('col-a'), log = firstOf('log-a'), shp = firstOf('shp-a');
        await bank.fetch(col);
        await bank.fetch(log);
        expect(lazy.residentPacks.toSet(), <String>{
          'voice-nitzi',
          'voice-nitzi-part-col-a',
          'voice-nitzi-part-log-a',
        });
        await bank.fetch(shp);
        expect(lazy.residentPacks.toSet(), <String>{
          'voice-nitzi',
          'voice-nitzi-part-log-a',
          'voice-nitzi-part-shp-a',
        });
        expect(bank.clip(col), isNull, reason: 'col-a is out of memory');
        expect(bank.canLoad(col), isTrue);
        expect(bank.clip(log), isNotNull);
        expect(bank.clip(firstOf('core')), isNotNull);
        // Using log makes shp the oldest; col comes back and shp goes.
        await bank.fetch(col);
        expect(lazy.residentPacks.toSet(), <String>{
          'voice-nitzi',
          'voice-nitzi-part-log-a',
          'voice-nitzi-part-col-a',
        });
        // Five parts asked for at the same moment still end with the bound.
        final List<String> ids = <String>[
          for (final String g in <String>['num-a-1', 'num-b-1', 'math-b-1', 'cs-a', 'shp-b'])
            _anyOf(bank, 'voice-nitzi-part-$g'),
        ];
        await Future.wait(<Future<VoiceClip?>>[for (final String id in ids) bank.fetch(id)]);
        expect(lazy.residentPacks.where((String p) => p != 'voice-nitzi').length, lessThanOrEqualTo(2));
        expect(lazy.residentPacks, contains('voice-nitzi'));
      },
    );

    test('a lesson prefetch reads the part of its lines (not more than two), and the director then says the line at once', () async {
      final VoiceBank bank = await source.voice('nitzi');
      final File lessonFile = Directory('../content/starter')
          .listSync()
          .whereType<File>()
          .firstWhere((File f) => f.path.contains('activity.b.numb03.') && f.path.endsWith('.json'));
      final List<String> ids = voiceLinesOf(<Map<String, Object?>>[
        jsonDecode(lessonFile.readAsStringSync()) as Map<String, Object?>,
      ]);
      expect(ids, isNotEmpty);
      final Set<String> partsNeeded = <String>{
        for (final String id in ids)
          if (bank.packs!.index[id] != 'voice-nitzi') bank.packs!.index[id]!,
      };
      expect(partsNeeded, isNotEmpty);
      await bank.prefetch(ids);
      expect(bank.packs!.residentPacks.toSet(), <String>{'voice-nitzi', ...partsNeeded});
      final FakePlayer player = FakePlayer();
      final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
      addTearDown(director.dispose);
      final String first = ids.firstWhere((String id) => bank.clip(id) != null);
      expect(bank.canLoad(first), isFalse, reason: 'nothing to wait for');
      await director.say(first);
      expect(player.plays, 1);
      expect(utf8.decode(player.played.single), 'nitzi|${textOf[first]}');
    });

    test('a friend says its own lines in its own voice, and every other line in the narrator\'s', () async {
      final VoiceBank narrator = await source.voice('nitzi');
      final VoiceBank own = await source.voice('inventor-gali');
      expect(own.length, 57);
      final VoiceBank friend = VoiceBank.withFallback(own, narrator);
      final String hello = 'vo:core.greeting.hello';
      expect(utf8.decode(friend.clip(hello)!.mp3), 'gali|${textOf[hello]}', reason: 'the friend\'s own line');
      final String lesson = firstOf('num-b');
      expect(friend.has(lesson), isTrue);
      expect(friend.canLoad(lesson), isTrue);
      expect(friend.clip(lesson), isNull, reason: 'the narrator\'s part is not in memory yet');
      expect(utf8.decode((await friend.fetch(lesson))!.mp3), 'nitzi|${textOf[lesson]}');
      expect(utf8.decode(friend.clip(lesson)!.mp3), 'nitzi|${textOf[lesson]}');
      // A narrator line that is also a friend's own (core.celebrate.well) stays the friend's.
      final String well = 'vo:core.celebrate.well';
      expect(utf8.decode(friend.clip(well)!.mp3), 'gali|${textOf[well]}');
      // The friend's prefetch reaches the narrator's pack.
      final VoiceBank other = VoiceBank.withFallback(
        await source.voice('inventor-gali'),
        await source.voice('nitzi'),
      );
      await other.prefetch(<String>[firstOf('shp-b')]);
      expect(other.fallback!.packs!.residentPacks, contains('voice-nitzi-part-shp-b'));
    });

    test('a tampered part pack is refused when it is read; its lines are silent, nothing else is, and nothing throws', () async {
      await smallPhone();
      final String col = firstOf('col-a'), log = firstOf('log-a');
      final File sound = soundOf('voice-nitzi-part-col-a', col);
      sound.writeAsBytesSync(<int>[...sound.readAsBytesSync(), 7]);
      final VoiceBank bank = await source.voice('nitzi');
      expect(
        bank.has(col),
        isTrue,
        reason: 'the index is from the manifest; the pack is proven when it is read',
      );
      final FakePlayer player = FakePlayer();
      final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
      addTearDown(director.dispose);
      await director.say(col);
      expect(player.plays, 0, reason: 'silent');
      expect(bank.packs!.failedPacks, <String>{'voice-nitzi-part-col-a'});
      expect(bank.has(col), isFalse, reason: 'as a line that was never recorded');
      expect(bank.packs!.residentPacks, isNot(contains('voice-nitzi-part-col-a')));
      // It does not poison the others, nor the shared pack.
      await director.say(log);
      expect(player.plays, 1);
      await director.say(firstOf('core'));
      expect(player.plays, 2);
      // Asking again does not read the bad pack again, and prefetch of its lines is harmless.
      await bank.prefetch(<String>[col]);
      expect(await bank.fetch(col), isNull);
    });

    test('a friend whose narrator part pack is tampered says nothing for those lines (no exception), and its own lines still play', () async {
      await smallPhone();
      final String col = firstOf('col-a');
      final File sound = soundOf('voice-nitzi-part-col-a', col);
      sound.writeAsBytesSync(<int>[...sound.readAsBytesSync(), 7]);
      final VoiceBank friend = VoiceBank.withFallback(
        await source.voice('inventor-gali'),
        await source.voice('nitzi'),
      );
      final FakePlayer player = FakePlayer();
      final VoiceDirector director = VoiceDirector(player: player)..useBank(friend);
      addTearDown(director.dispose);
      await director.say(col);
      expect(player.plays, 0);
      await director.say('vo:core.greeting.hello');
      expect(player.plays, 1);
      expect(utf8.decode(player.played.single), startsWith('gali|'));
    });

    test('a deleted part pack folder behaves the same: a missing clip', () async {
      await smallPhone();
      final String log = firstOf('log-a');
      Directory('${root.path}${Platform.pathSeparator}voice-nitzi-part-log-a').deleteSync(recursive: true);
      final VoiceBank bank = await source.voice('nitzi');
      expect(bank.has(log), isFalse, reason: 'its manifest is gone, so the index never had it');
      expect(await bank.fetch(log), isNull);
      expect(await bank.fetch(firstOf('col-a')), isNotNull);
    });
  });

  // B-45 job "the map-card line is voiced" (QA 2026-11-02): the 100 `core.skill.*` lines are the `skill` part pack; a land map
  // (or the Trophy Hall) prefetches it and says a line from it; a friend borrows the narrator's; a damaged pack is silence.
  group('the map-card lines (the skill part pack), through the real installer', () {
    late List<String> ids;
    late List<WorldObject> objects;

    setUpAll(() async {
      final content = await loadStarter();
      objects = <WorldObject>[
        for (final SkillDoc s in content.skills.values)
          if (s.childLine != null)
            WorldObject(
              skillId: s.id,
              title: s.title,
              objectId: 'stair',
              stage: GrowthStage.fruit,
              bell: false,
              line: s.childLine,
            ),
      ];
      ids = <String>[for (final WorldObject o in objects) skillLineVoiceId(o.skillId)!];
    });

    test('every skill of the starter pack has its line in one pack, voice-nitzi-part-skill, and that pack holds only them', () async {
      expect(ids.length, 100);
      expect(ids.toSet().length, 100);
      final VoiceBank bank = await full.source.voice('nitzi');
      for (final String id in ids) {
        expect(bank.has(id), isTrue, reason: id);
        expect(bank.packs!.index[id], 'voice-nitzi-part-skill', reason: id);
      }
      final Set<String> inPack = <String>{
        for (final MapEntry<String, String> e in bank.packs!.index.entries)
          if (e.value == 'voice-nitzi-part-skill') e.key,
      };
      expect(inPack, ids.toSet(), reason: 'the pack holds exactly the 100 map-card lines');
      expect(bank.packs!.residentPacks, <String>[
        'voice-nitzi',
      ], reason: 'not read before the island or the hall opens');
    });

    test('the island prefetches it once and a touch is then heard at once; a second line replaces, the same twice stops', () async {
      final VoiceBank bank = await full.source.voice('nitzi');
      final FakePlayer player = FakePlayer();
      final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
      addTearDown(director.dispose);
      expect(bank.canLoad(ids.first), isTrue);
      await director.prefetch(cardLineVoiceIds(objects));
      expect(bank.packs!.residentPacks.toSet(), <String>{'voice-nitzi', 'voice-nitzi-part-skill'});
      expect(bank.canLoad(ids.first), isFalse, reason: 'nothing to wait for');
      final Object owner = Object();
      await director.say(ids[0], owner: owner);
      expect(utf8.decode(player.played.single), 'nitzi|${textOf[ids[0]]}');
      await director.say(ids[57], owner: owner);
      expect(utf8.decode(player.played.last), 'nitzi|${textOf[ids[57]]}');
      expect(player.plays, 2);
      expect(player.playing, isTrue);
      await director.stopFor(owner);
      expect(player.playing, isFalse);
      // The last line of the pack too (the pack is read whole, not part).
      await director.say(ids.last, owner: owner);
      expect(utf8.decode(player.played.last), 'nitzi|${textOf[ids.last]}');
    });

    test('every one of the 100 lines plays its own sound (no two lines share a sound)', () async {
      final VoiceBank bank = await full.source.voice('nitzi');
      await bank.prefetch(ids);
      final Set<String> heard = <String>{};
      for (final String id in ids) {
        final VoiceClip? clip = bank.clip(id);
        expect(clip, isNotNull, reason: id);
        expect(utf8.decode(clip!.mp3), 'nitzi|${textOf[id]}', reason: id);
        expect(clip.mouth.length, greaterThan(0), reason: id);
        heard.add(utf8.decode(clip.mp3));
      }
      expect(heard.length, 100, reason: 'no two lines share a sound');
    });

    test('a friend (any of the nine) says a map-card line in the narrator voice, and its director prefetches the narrator skill pack', () async {
      final VoiceBank narrator = await full.source.voice('nitzi');
      final VoiceBank own = await full.source.voice('inventor-gali');
      expect(own.has(ids.first), isFalse, reason: 'a friend has only its own lines');
      final VoiceBank friend = VoiceBank.withFallback(own, narrator);
      expect(friend.has(ids.first), isTrue);
      final FakePlayer player = FakePlayer();
      final VoiceDirector director = VoiceDirector(player: player)..useBank(friend);
      addTearDown(director.dispose);
      await director.prefetch(<String>[ids[3]]);
      expect(narrator.packs!.residentPacks, contains('voice-nitzi-part-skill'));
      await director.say(ids[3]);
      expect(utf8.decode(player.played.single), 'nitzi|${textOf[ids[3]]}');
    });

    test('a damaged skill pack is silence for the 100 lines (no error), and the shared lines still play', () async {
      final _Phone small = await _Phone.open(key, <BuiltPack>[
        for (final BuiltPack b in nitzi)
          if (<String>{
            'voice-nitzi-2.0.0.nnpack',
            'voice-nitzi-part-skill-2.0.0.nnpack',
          }.contains(b.fileName))
            b,
      ]);
      addTearDown(small.close);
      final File sound = File(
        '${small.root.path}${Platform.pathSeparator}voice-nitzi-part-skill${Platform.pathSeparator}2.0.0${Platform.pathSeparator}vo.${ids.first.substring(3)}.mp3',
      );
      sound.writeAsBytesSync(<int>[...sound.readAsBytesSync(), 7]);
      final VoiceBank bank = await small.source.voice('nitzi');
      final FakePlayer player = FakePlayer();
      final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
      addTearDown(director.dispose);
      await director.prefetch(ids);
      await director.say(ids[1]);
      expect(player.plays, 0, reason: 'the whole pack is refused, so every one of its lines is silent');
      expect(bank.packs!.failedPacks, <String>{'voice-nitzi-part-skill'});
      await director.say('vo:core.greeting.hello');
      expect(player.plays, 1);
    });
  });

  group('the size guard and the free re-pack, on the real ids', () {
    test('a pack of 100 KiB clips is over 40 MiB: the build fails naming it; a re-pack with fewer lines passes verifyPack under ZipLimits', () async {
      final VoiceProfile profile = VoiceProfile.fromConfig(_config(), 'nitzi');
      // The 440 lines of the largest pack (num-a-1) at a worst-case clip size, not all 4,166 (to keep the run small).
      final List<VoicePackGroup> layout = voicePackLayout('nitzi', profile, _planned);
      final VoicePackGroup biggest = layout.reduce(
        (VoicePackGroup a, VoicePackGroup b) => a.voIds.length >= b.voIds.length ? a : b,
      );
      expect(biggest.voIds.length, greaterThan(400));
      final Set<String> take = biggest.voIds.toSet();
      final List<SpokenLine> lines = <SpokenLine>[
        for (final SpokenLine l in _planned)
          if (take.contains(l.voId)) l,
      ];
      final String subsetPack = voicePackLayout('nitzi', profile, lines).single.packId;
      final Directory work = Directory('${scratch.path}/big');
      addTearDown(() => _drop(work));
      await expectLater(
        generateVoicePack(
          characterId: 'nitzi',
          lines: lines,
          synth: _Tagged('nitzi', pad: 100 * 1024),
          profile: profile,
          key: key,
          workDir: work,
          version: '2.0.0',
        ),
        throwsA(
          isA<VoiceGenFailed>()
              .having((VoiceGenFailed e) => e.message, 'names the pack', contains(subsetPack))
              .having((VoiceGenFailed e) => e.message, 'says how to fix it', contains('--max-lines'))
              .having(
                (VoiceGenFailed e) => e.message,
                'says nothing was signed',
                contains('No pack was signed'),
              ),
        ),
      );
      // The clips are saved; the re-pack with fewer lines (free) builds packs that all verify.
      final List<BuiltPack> again = await repackVoicePacks(
        characterId: 'nitzi',
        lines: lines,
        profile: profile,
        key: key,
        workDir: work,
        version: '2.0.0',
        maxLines: 200,
      );
      expect(again.length, greaterThan(1));
      final Set<String> seen = <String>{};
      for (final BuiltPack b in again) {
        final VerifiedPack p = await verifyPack(b.bytes, publicKey: key.publicKey);
        expect(b.bytes.length, lessThanOrEqualTo(VoicePackLimits.maxBytes), reason: p.id);
        for (final Object? v in p.manifest['vo']! as List<Object?>) {
          expect(seen.add('vo:${(v! as Map<String, Object?>)['id']}'), isTrue);
        }
      }
      expect(seen, take);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}

String _anyOf(VoiceBank bank, String packId) =>
    bank.packs!.index.entries.firstWhere((MapEntry<String, String> e) => e.value == packId).key;

/// An installed set of packs on a temporary folder.
class _Phone {
  _Phone._(this.dir, this.root, this.db, this.installer, this.source);

  final Directory dir;
  final Directory root;
  final AppDatabase db;
  final PackInstaller installer;
  final InstalledCharacterSource source;

  static Future<_Phone> open(PackKey key, Iterable<BuiltPack> packs) async {
    final Directory dir = Directory.systemTemp.createTempSync('nn_qa_b45_inst_');
    final Directory root = Directory('${dir.path}${Platform.pathSeparator}packs');
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final PackInstaller installer = PackInstaller(
      root: root,
      registry: DbPackRegistry(db),
      publicKey: key.publicKey,
      capabilities: AppCapabilities.current,
    );
    for (final BuiltPack b in packs) {
      await installer.install(b.bytes);
    }
    return _Phone._(
      dir,
      root,
      db,
      installer,
      InstalledCharacterSource(installer: installer, bundledHouse: () async => Uint8List(0)),
    );
  }

  Future<void> close() async {
    await db.close();
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}
