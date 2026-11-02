// B-45: a narrator's voice is several packs, none over 40 MiB or 3,000 files (tool/voice_packs_lib.dart). The share of the
// lines among the packs is a pure function of the voice ids, tested here on the ids of the real content.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/zip_store.dart';
import 'package:nitznutz/voice/voice_pack_ids.dart';

import '../tool/voice_gen_lib.dart';

/// Every voice id the content asks for: the lessons and activities of the starter pack, and the core lines.
final List<String> _realIds = <String>{
  for (final SpokenLine l in linesOfContent(Directory('../content/starter'))) l.voId,
  for (final SpokenLine l in coreLines(File('../content/lines/core.he.json'))) l.voId,
}.toList()..sort();

/// [count] lines of one skill: `b.<skill>.1.prompt` ...
List<String> _skill(String skill, int count) => <String>[
  for (int i = 1; i <= count; i++) 'vo:b.$skill.$i.prompt',
];

void main() {
  group('the group of a voice id', () {
    test('the shared lines are core', () {
      for (final String id in <String>[
        'vo:core.greeting.hello',
        'vo:fb.part_miss',
        'vo:hint.plate.h2',
        'vo:celebrate.make_ten',
      ]) {
        expect(voiceGroupOf(id), 'core', reason: id);
      }
    });

    test('a skill id goes to its land and band, whichever batch wrote it', () {
      expect(voiceGroupOf('vo:b.numb03.8.correct'), 'num-b');
      expect(voiceGroupOf('vo:b15.numa13.1.h1'), 'num-a');
      expect(voiceGroupOf('vo:b36.cola05.2.prompt'), 'col-a');
      expect(voiceGroupOf('vo:x.mathb15.3.h3'), 'math-b');
      expect(voiceGroupOf('vo:b.logb04.10.h3'), 'log-b');
      expect(voiceGroupOf('vo:b.shpb08.10.prompt'), 'shp-b');
      expect(voiceGroupOf('vo:b.csb01.2.prompt'), 'cs-b');
    });

    test('the first lessons go by the start of their id: a land, or the number lessons, in band A', () {
      expect(voiceGroupOf('vo:col.find.1.prompt'), 'col-a');
      expect(voiceGroupOf('vo:math.time.noon.h3'), 'math-a');
      expect(voiceGroupOf('vo:shp.line.3.prompt'), 'shp-a');
      expect(voiceGroupOf('vo:cs.robot.4.prompt'), 'cs-a');
      expect(voiceGroupOf('vo:count.apples.1.prompt'), 'num-a');
      expect(voiceGroupOf('vo:ordinal.first.2.correct'), 'num-a');
    });

    test('an id nothing here knows is core, with or without vo:', () {
      expect(voiceGroupOf('vo:welcome.daily.1'), 'core');
      expect(voiceGroupOf('welcome.daily.1'), 'core');
      expect(voiceGroupOf('b.numb03.8.correct'), 'num-b');
      expect(voiceGroupOf('vo:b.nothing.8.correct'), 'core');
    });

    test('the unit of a line is its skill, or else the first two parts of its id', () {
      expect(voiceUnitOf('vo:b.numb03.8.correct'), 'numb03');
      expect(voiceUnitOf('vo:b15.numb03.1.h1'), 'numb03', reason: 'one skill in two batches stays together');
      expect(voiceUnitOf('vo:col.find.1.prompt'), 'col.find');
      expect(voiceUnitOf('vo:celebrate.make_ten'), 'celebrate.make_ten');
      expect(voiceUnitOf('vo:alone'), 'alone');
    });
  });

  group('the layout of a character\'s packs', () {
    test('a group that fits is one pack, named by its group; the shared lines have the plain pack id', () {
      final List<VoicePackGroup> packs = layoutVoicePacks('nitzi', <String>[
        'vo:core.greeting.hello',
        'vo:b.numb03.1.prompt',
        'vo:b.numb03.2.prompt',
        'vo:col.find.1.prompt',
      ]);
      expect(packs.map((VoicePackGroup p) => p.packId), <String>[
        'voice-nitzi',
        'voice-nitzi-part-col-a',
        'voice-nitzi-part-num-b',
      ]);
      expect(packs.map((VoicePackGroup p) => p.name), <String>['core', 'col-a', 'num-b']);
    });

    test('a group over the line limit is cut into numbered parts, never inside a skill', () {
      final List<String> ids = <String>[
        ..._skill('numb01', 3),
        ..._skill('numb02', 3),
        ..._skill('numb03', 3),
      ];
      final List<VoicePackGroup> packs = layoutVoicePacks('nitzi', ids, maxLines: 6);
      expect(packs.map((VoicePackGroup p) => p.name), <String>['num-b-1', 'num-b-2']);
      expect(packs[0].voIds, <String>[..._skill('numb01', 3), ..._skill('numb02', 3)]);
      expect(packs[1].voIds, _skill('numb03', 3));
      // A limit of 4 cannot cut a skill of 3 lines in the middle: each skill is a part of its own.
      expect(layoutVoicePacks('nitzi', ids, maxLines: 4).map((VoicePackGroup p) => p.voIds.length), <int>[
        3,
        3,
        3,
      ]);
    });

    test('a skill bigger than the limit is a part of its own (the size guard judges it)', () {
      final List<VoicePackGroup> packs = layoutVoicePacks('nitzi', <String>[
        ..._skill('numb01', 5),
        ..._skill('numb02', 1),
      ], maxLines: 2);
      expect(packs.map((VoicePackGroup p) => p.voIds.length), <int>[5, 1]);
    });

    test(
      'every id lands in exactly one pack, whatever the order it comes in, and the layout is always the same',
      () {
        final List<String> ids = <String>[
          ..._skill('numb01', 4),
          ..._skill('mathb02', 4),
          'vo:core.greeting.hello',
          'vo:fb.ord',
          'vo:col.find.1.prompt',
        ];
        final List<VoicePackGroup> a = layoutVoicePacks('nitzi', ids, maxLines: 3);
        final List<VoicePackGroup> b = layoutVoicePacks('nitzi', ids.reversed.toList(), maxLines: 3);
        String shape(List<VoicePackGroup> l) =>
            <String>[for (final VoicePackGroup p in l) '${p.packId}: ${p.voIds}'].join('\n');
        expect(shape(b), shape(a));
        final List<String> all = <String>[for (final VoicePackGroup p in a) ...p.voIds];
        expect(all.length, ids.length);
        expect(all.toSet(), ids.toSet());
      },
    );

    test('a line added to one land changes no other land\'s pack', () {
      final List<String> ids = <String>[
        ..._skill('numb01', 2),
        ..._skill('mathb02', 2),
        'vo:core.greeting.hello',
      ];
      final List<VoicePackGroup> before = layoutVoicePacks('nitzi', ids);
      final List<VoicePackGroup> after = layoutVoicePacks('nitzi', <String>[...ids, 'vo:b.numb09.1.prompt']);
      List<String> of(List<VoicePackGroup> l, String name) =>
          l.firstWhere((VoicePackGroup p) => p.name == name).voIds;
      expect(of(after, 'math-b'), of(before, 'math-b'));
      expect(of(after, 'core'), of(before, 'core'));
      expect(of(after, 'num-b'), <String>[...of(before, 'num-b'), 'vo:b.numb09.1.prompt']);
    });

    test('a friend\'s few lines are one pack, whatever their ids', () {
      final List<VoicePackGroup> packs = layoutVoicePacks('tower-tamir', <String>[
        'vo:core.greeting.hello',
        'vo:b.numb03.1.prompt',
        'vo:col.find.1.prompt',
      ], onePack: true);
      expect(packs.single.packId, 'voice-tower-tamir');
      expect(packs.single.voIds, hasLength(3));
    });

    test('a line twice is one line', () {
      final List<VoicePackGroup> packs = layoutVoicePacks('nitzi', <String>['vo:core.a', 'vo:core.a']);
      expect(packs.single.voIds, <String>['vo:core.a']);
    });

    test('nothing at all is no pack', () {
      expect(layoutVoicePacks('nitzi', const <String>[]), isEmpty);
    });

    test('a character id that holds the part marker, or makes a pack id too long, is refused before anything is sent', () {
      expect(
        () => layoutVoicePacks('hero-part-two', <String>['vo:core.a']),
        throwsA(isA<VoiceGenFailed>().having((VoiceGenFailed e) => e.message, 'message', contains('-part-'))),
      );
      expect(
        () => layoutVoicePacks('a' * 30, <String>['vo:b.numb03.1.prompt']),
        throwsA(
          isA<VoiceGenFailed>().having((VoiceGenFailed e) => e.message, 'message', contains('not a pack id')),
        ),
      );
      expect(
        () => layoutVoicePacks('nitzi', <String>['vo:core.a'], maxLines: 0),
        throwsA(isA<VoiceGenFailed>()),
      );
    });

    test(
      'a unit too big for the file limit is refused when the lines are planned, not after they are paid for',
      () {
        final List<String> ids = _skill('numb07', 1500);
        expect(
          () => layoutVoicePacks('nitzi', ids),
          throwsA(
            isA<VoiceGenFailed>().having((VoiceGenFailed e) => e.message, 'message', contains('3002 files')),
          ),
        );
        expect(layoutVoicePacks('nitzi', _skill('numb07', 1499)).single.entries, 3000);
      },
    );
  });

  group('the real content', () {
    final Map<String, Object?> voices =
        jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;
    final List<String> characters = ((voices['voices']! as Map<String, Object?>).keys).toList()..sort();
    final List<VoicePackGroup> packs = layoutVoicePacks('nitzi', _realIds);

    test('is read: about four thousand lines', () {
      expect(_realIds.length, greaterThan(3900));
    });

    test('every planned id lands in exactly one pack, and no pack holds an id twice', () {
      final List<String> all = <String>[for (final VoicePackGroup p in packs) ...p.voIds];
      expect(all.length, _realIds.length);
      expect(all.toSet(), _realIds.toSet());
      for (final String id in _realIds) {
        expect(packs.where((VoicePackGroup p) => p.voIds.contains(id)), hasLength(1), reason: id);
      }
    });

    test(
      'every pack is far under the limits of a voice pack, and of the app (ZipLimits), at 60 KiB a clip',
      () {
        for (final VoicePackGroup p in packs) {
          expect(p.entries, lessThanOrEqualTo(VoicePackLimits.maxEntries), reason: p.packId);
          expect(p.entries, lessThan(ZipLimits.maxEntries), reason: p.packId);
          final int estimated = p.voIds.length * VoicePackLimits.estimatedClipBytes;
          expect(
            estimated,
            lessThanOrEqualTo(VoicePackLimits.maxBytes),
            reason: '${p.packId} ${p.voIds.length}',
          );
          expect(estimated, lessThan(ZipLimits.maxTotalBytes), reason: p.packId);
        }
        expect(VoicePackLimits.maxBytes, lessThan(ZipLimits.maxTotalBytes));
        expect(VoicePackLimits.maxEntries, lessThan(ZipLimits.maxEntries));
      },
    );

    test(
      'the shared lines are one pack, with the plain id (the pack that was always called voice-<character>)',
      () {
        final List<VoicePackGroup> core = packs
            .where((VoicePackGroup p) => p.name.startsWith('core'))
            .toList();
        expect(core.single.packId, 'voice-nitzi');
        expect(core.single.name, 'core', reason: 'a second core pack would take the plain id away');
      },
    );

    test('a land and band of the content is never lumped into core by mistake: core holds only the shared families', () {
      const Set<String> shared = <String>{'core', 'fb', 'hint', 'celebrate'};
      final List<String> stray = <String>[
        for (final String id in packs.firstWhere((VoicePackGroup p) => p.name == 'core').voIds)
          if (!shared.contains(id.substring(3).split('.').first)) id,
      ];
      expect(stray, isEmpty, reason: 'decide where these go in voiceGroupOf: $stray');
    });

    test(
      'the packs of every character have valid ids, and no character\'s packs can be taken for another\'s',
      () {
        for (final String c in characters) {
          expect(hasPlainVoiceId(c), isTrue, reason: c);
          for (final VoicePackGroup p in layoutVoicePacks(c, _realIds)) {
            expect(p.packId.length, lessThanOrEqualTo(41), reason: p.packId);
            for (final String other in characters) {
              expect(isVoicePackOf(other, p.packId), other == c, reason: '${p.packId} against $other');
            }
            expect(characterOfVoicePack(p.packId), c);
          }
        }
      },
    );

    test('the plan shows each pack with its lines, characters and estimated size', () {
      final String text = describeVoicePacks(
        'nitzi',
        packs,
        <String, int>{for (final String id in _realIds) id: 10},
        version: '2.0.0',
        maxLines: VoicePackLimits.maxLines,
      );
      expect(
        text,
        contains('Voice packs of nitzi, version 2.0.0: ${packs.length} packs, ${_realIds.length} lines'),
      );
      expect(text, contains('voice-nitzi-part-num-b-1'));
      expect(text, contains('60 KiB a clip'));
      expect(text.split('\n').where((String l) => l.startsWith('  voice-')), hasLength(packs.length));
    });
  });

  group('the pack ids', () {
    test('are told apart by the part marker', () {
      expect(voicePackId('nitzi'), 'voice-nitzi');
      expect(voicePackId('nitzi', 'num-b-2'), 'voice-nitzi-part-num-b-2');
      expect(isVoicePackOf('nitzi', 'voice-nitzi'), isTrue);
      expect(isVoicePackOf('nitzi', 'voice-nitzi-part-col-a'), isTrue);
      expect(
        isVoicePackOf('hero', 'voice-hero-son'),
        isFalse,
        reason: 'another character, not a part of hero',
      );
      expect(isVoicePackOf('hero', 'voice-hero-son-part-col-a'), isFalse);
      expect(isVoicePackOf('nitzi', 'char-nitzi'), isFalse);
      expect(characterOfVoicePack('voice-hero-son-part-col-a'), 'hero-son');
      expect(characterOfVoicePack('voice-hero-son'), 'hero-son');
      expect(characterOfVoicePack('starter'), 'starter');
    });
  });

  group('the size guard', () {
    final List<VoicePackGroup> packs = layoutVoicePacks('nitzi', <String>[
      ..._skill('numb01', 10),
      ..._skill('mathb01', 10),
    ]);
    const int mib = 1024 * 1024;

    test('lets packs at or under the limit through', () {
      checkVoicePackSizes('nitzi', packs, <String, int>{
        for (final VoicePackGroup p in packs) p.packId: VoicePackLimits.maxBytes,
      });
    });

    test(
      'names every pack over the limit, says nothing was signed or lost, and suggests a smaller --max-lines',
      () {
        expect(
          () => checkVoicePackSizes('nitzi', packs, <String, int>{
            packs[0].packId: 80 * mib,
            packs[1].packId: 10 * mib,
          }),
          throwsA(
            isA<VoiceGenFailed>()
                .having((VoiceGenFailed e) => e.message, 'names the pack', contains(packs[0].packId))
                .having((VoiceGenFailed e) => e.message, 'only the big one', isNot(contains(packs[1].packId)))
                .having((VoiceGenFailed e) => e.message, 'size', contains('80.0 MiB'))
                .having((VoiceGenFailed e) => e.message, 'free', contains('none needs to be paid for again'))
                .having(
                  (VoiceGenFailed e) => e.message,
                  'how',
                  contains('voice_gen.dart pack nitzi --max-lines 4'),
                ),
          ),
        );
      },
    );
  });
}
