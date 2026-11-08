// Voicing in batches (the owner's allowance is smaller than the release): whole groups from the voice director's manifest,
// a budget that stops before the first group that would not fit, clips made by an earlier run copied for free, and the free
// `verify`. A pretend ElevenLabs (a mock HTTP client): nothing leaves the test, and no key is read.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import '../tool/voice_groups_lib.dart';
import 'support/fake_eleven.dart';
import 'support/pack_fixtures.dart';

Directory _temp(String name) => Directory.systemTemp.createTempSync(name);

void _drop(Directory d) {
  for (final FileSystemEntity e in <FileSystemEntity>[
    d,
    File('${d.path}.voiced.jsonl'),
    Directory('${d.path}.pack-stage'),
  ]) {
    try {
      e.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}

const VoiceProfile _v4 = VoiceProfile(
  voiceId: 'VoiceXyz0123',
  modelId: 'eleven_v4',
  outputFormat: 'mp3_44100_64',
  settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
);

File _manifestFile(Directory dir, Object? doc) =>
    File('${dir.path}${Platform.pathSeparator}voicing-groups.json')..writeAsStringSync(jsonEncode(doc));

Map<String, Object?> _group(String name, List<String> ids) => <String, Object?>{
  'name': name,
  'ids': ids,
  'chars': 0,
};

/// A voice that answers every line with a large sound, to see a pack that is over the limit.
class _BigVoice implements Synthesizer {
  @override
  Future<Synthesis> say(ClipRequest request) async => Synthesis(
    Uint8List(15 * 1024 * 1024),
    'mp3',
    const Alignment(<String>['א'], <double>[0], <double>[0.1]),
  );
}

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());

  group('the voice director\'s groups', () {
    late Directory tmp;
    setUp(() => tmp = _temp('nn_grp_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('are read in order, each id in one group, and --groups names are checked against them', () {
      final GroupManifest m = GroupManifest.read(
        _manifestFile(tmp, <String, Object?>{
          'schema': 'voicing-groups/v1',
          'groups': <Object?>[
            _group('core', <String>['vo:core.a']),
            _group('numbers-A', <String>['vo:n.a', 'vo:n.b']),
            _group('math-A', <String>['vo:m.a']),
          ],
        }),
      );
      expect(m.names, <String>['core', 'numbers-A', 'math-A']);
      expect(m.groupOf['vo:n.b'], 'numbers-A');
      expect(m.order, <String>['core', 'numbers-A', 'math-A', 'ui']);
      expect(m.pick('math-A, core'), <String>['core', 'math-A'], reason: 'run order, not the order typed');
      expect(m.pick('ui'), <String>['ui']);
      expect(() => m.pick('core,nope'), throwsA(isA<VoiceGenFailed>()));
      expect(() => m.pick(''), throwsA(isA<VoiceGenFailed>()));
    });

    test('a missing file, another schema, a name twice and an id in two groups are refused', () {
      expect(() => GroupManifest.read(File('${tmp.path}/none.json')), throwsA(isA<VoiceGenFailed>()));
      expect(
        () => GroupManifest.read(_manifestFile(tmp, <String, Object?>{'schema': 'x', 'groups': <Object?>[]})),
        throwsA(isA<VoiceGenFailed>()),
      );
      Map<String, Object?> doc(List<Object?> groups) => <String, Object?>{
        'schema': 'voicing-groups/v1',
        'groups': groups,
      };
      expect(
        () => GroupManifest.read(
          _manifestFile(tmp, doc(<Object?>[_group('a', <String>[]), _group('a', <String>[])])),
        ),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => GroupManifest.read(
          _manifestFile(
            tmp,
            doc(<Object?>[
              _group('a', <String>['vo:x']),
              _group('b', <String>['vo:x']),
            ]),
          ),
        ),
        throwsA(isA<VoiceGenFailed>()),
      );
    });

    test(
      'lines get their group, the shell lines keep ui, and a line the manifest does not know has none',
      () {
        const VoiceTexts texts = VoiceTexts(<VoicedLine>[
          VoicedLine(voId: 'vo:a', text: 'x', rows: <String>[]),
          VoicedLine(voId: 'vo:b', text: 'x', rows: <String>[]),
          VoicedLine(voId: 'vo:u', text: 'x', rows: <String>[], ui: true, group: uiGroup),
        ]);
        final VoiceTexts grouped = texts.withGroups(<String, String>{'vo:a': 'first'});
        expect(grouped.lines.map((VoicedLine l) => l.group), <String>['first', '', 'ui']);
        expect(grouped.inGroups(<String>{'first', 'ui'}).lines.map((VoicedLine l) => l.voId), <String>[
          'vo:a',
          'vo:u',
        ]);
        expect(groupNames(grouped.lines, <String>['ui', 'first']), <String>['ui', 'first']);
      },
    );

    test('the real manifest names only lines that exist, and every line of the release is in a group', () {
      final GroupManifest m = GroupManifest.read(File('../docs/audio/voicing-groups.json'));
      final Map<String, MasterRow> master = readMaster(
        File('../docs/review/hebrew-master.csv').readAsStringSync(),
      );
      final VoiceTexts texts = voiceTextsOf(
        content: Directory('../content/starter'),
        core: File('../content/lines/core.he.json'),
        master: master,
      );
      final Set<String> ids = texts.lines.map((VoicedLine l) => l.voId).toSet();
      expect(
        m.groupOf.keys.where((String id) => !ids.contains(id)),
        isEmpty,
        reason: 'run python tools/voicing_groups.py: the manifest names lines that are gone',
      );
      expect(
        ids.where((String id) => !m.groupOf.containsKey(id)),
        isEmpty,
        reason: 'run python tools/voicing_groups.py: lines are in no group',
      );
      expect(m.names.first, 'core');
      expect(m.names, contains('numbers-A'));
    });
  });

  group('choosing whole groups under a budget', () {
    // Each group costs its own number of characters; no sounds are shared.
    const Map<String, int> cost = <String, int>{'a': 10, 'b': 50, 'c': 5, 'd': 0};
    int costOf(Set<String> groups) => groups.fold<int>(0, (int s, String g) => s + cost[g]!);

    test('without a budget every group that is ready is in the run', () {
      final BatchChoice c = chooseBatch(
        candidates: <String>['a', 'b', 'c'],
        waiting: <String>{'c'},
        costOf: costOf,
      );
      expect(c.chosen, <String>['a', 'b']);
      expect(c.waiting, <String>['c']);
      expect(c.left, isEmpty);
      expect(c.total, 60);
    });

    test('the run stops before the first group that would not fit, even when a later one would', () {
      final BatchChoice c = chooseBatch(
        candidates: <String>['a', 'b', 'c'],
        waiting: <String>{},
        costOf: costOf,
        maxCharacters: 20,
      );
      expect(c.chosen, <String>['a']);
      expect(c.left, <String>['b', 'c'], reason: 'c would fit, but the groups are taken in order');
      expect(c.total, 10);
      expect(c.leftCharacters, <String, int>{'b': 50, 'c': 5});
      expect(c.leftTotal, 55);
      final String text = c.describe(maxCharacters: 20);
      expect(text, contains('Groups in this run (1): a; 10 characters (limit 20)'));
      expect(
        text,
        contains('Left for next time (2 groups, 55 characters; whole groups, none is split): b 50, c 5'),
      );
      expect(text, contains('Larger than the limit on its own, so it needs a higher budget: b'));
    });

    test('a group that costs nothing (all made) is always in, and the budget is a limit, not a target', () {
      expect(
        chooseBatch(
          candidates: <String>['d', 'a'],
          waiting: <String>{},
          costOf: costOf,
          maxCharacters: 10,
        ).chosen,
        <String>['d', 'a'],
      );
      expect(
        chooseBatch(candidates: <String>['a'], waiting: <String>{}, costOf: costOf, maxCharacters: 9).chosen,
        isEmpty,
      );
      expect(
        chooseBatch(
          candidates: <String>['b', 'a'],
          waiting: <String>{},
          costOf: costOf,
          maxCharacters: 0,
        ).total,
        0,
      );
    });

    test('a group waiting for the owner is passed over, not counted as left for the allowance', () {
      final BatchChoice c = chooseBatch(
        candidates: <String>['a', 'b', 'c'],
        waiting: <String>{'b'},
        costOf: costOf,
        maxCharacters: 15,
      );
      expect(c.chosen, <String>['a', 'c']);
      expect(c.waiting, <String>['b']);
      expect(c.describe(maxCharacters: 15), contains('Waiting for the owner to approve their rows'));
    });
  });

  group('what a run does with each line', () {
    test('lines in scope and lines made are in the run; a line left for later is not', () {
      final List<LineWork> w = workForLines(
        ids: <String>['a', 'b', 'c'],
        keys: <String>['ka', 'kb', 'kc'],
        made: <bool>[false, true, false],
        inScope: <bool>[true, false, false],
      );
      expect(w.map((LineWork x) => x.active), <bool>[true, true, false]);
      expect(w.every((LineWork x) => x.copyFrom == null), isTrue);
    });

    test(
      'a line out of scope with the text of one in scope is a free copy, and does not become the holder',
      () {
        final List<LineWork> w = workForLines(
          ids: <String>['far', 'near'],
          keys: <String>['k', 'k'],
          made: <bool>[false, false],
          inScope: <bool>[false, true],
        );
        expect(w[0].active, isTrue);
        expect(w[0].copyFrom, 'near');
        expect(w[1].copyFrom, isNull, reason: 'the line of the group in the run is the one that is voiced');
      },
    );

    test('a clip made for a line that is not in the list is copied by a new line with the same text', () {
      final List<LineWork> w = workForLines(
        ids: <String>['new'],
        keys: <String>['k'],
        made: <bool>[false],
        inScope: <bool>[false],
        elsewhere: <String, String>{'k': 'old'},
      );
      expect(w.single.active, isTrue);
      expect(w.single.copyFrom, 'old');
    });

    test('without sharing nothing is copied, and a line is in the run when made or in scope', () {
      final List<LineWork> w = workForLines(
        ids: <String>['a', 'b'],
        keys: <String>['k', 'k'],
        made: <bool>[false, false],
        inScope: <bool>[true, false],
        elsewhere: <String, String>{'k': 'old'},
        share: false,
      );
      expect(w.map((LineWork x) => x.active), <bool>[true, false]);
      expect(w.every((LineWork x) => x.copyFrom == null), isTrue);
    });

    test('the plan of a scope counts the characters of the groups in it, once each sound', () {
      final VoicePlan plan = planVoices(
        <String, VoiceProfile>{'nitzi': _v4},
        const <SpokenLine>[
          SpokenLine('vo:g1.a', 'שלום'),
          SpokenLine('vo:g1.b', 'כן'),
          SpokenLine('vo:g2.a', 'שלום'),
          SpokenLine('vo:g2.b', 'לא נכון'),
        ],
        scope: <String>{'vo:g1.a', 'vo:g1.b'},
      );
      expect(plan.total, 6);
      expect(plan.clips.map((PlannedClip c) => c.line.voId), <String>['vo:g1.a', 'vo:g1.b', 'vo:g2.a']);
      expect(plan.clips.last.copyOf, 'vo:g1.a');
      expect(
        planVoices(
          <String, VoiceProfile>{'nitzi': _v4},
          const <SpokenLine>[SpokenLine('vo:g2.a', 'שלום')],
          scope: <String>{},
        ).total,
        0,
      );
    });
  });

  group('batches of one voice, one after the other', () {
    late FakeEleven server;
    late Directory work;
    setUp(() {
      server = FakeEleven();
      work = _temp('nn_batch_');
    });
    tearDown(() => _drop(work));

    Future<BuiltPack> run(List<SpokenLine> lines, Set<String>? scope, {bool share = true}) =>
        generateVoicePack(
          characterId: 'nitzi',
          lines: lines,
          synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: server.client),
          profile: _v4,
          key: key,
          workDir: work,
          scope: scope,
          shareSameText: share,
        );

    Future<VoiceBank> bank(BuiltPack built) async =>
        VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));

    const List<SpokenLine> lines = <SpokenLine>[
      SpokenLine('vo:g1.a', 'שָׁלוֹם'),
      SpokenLine('vo:g1.b', 'כֵּן'),
      SpokenLine('vo:g2.a', 'לֹא'),
      SpokenLine('vo:g2.b', 'שָׁלוֹם'),
    ];

    test('the first batch voices its group and the free copies; the pack holds only those', () async {
      final VoiceBank first = await bank(await run(lines, <String>{'vo:g1.a', 'vo:g1.b'}));
      expect(server.requests.length, 2);
      expect(first.ids.toSet(), <String>{
        'vo:g1.a',
        'vo:g1.b',
        'vo:g2.b',
      }, reason: 'g2.b has the text of g1.a');
    });

    test(
      'the second batch sends only its own group, and the pack then holds everything made so far',
      () async {
        await run(lines, <String>{'vo:g1.a', 'vo:g1.b'});
        final VoiceBank second = await bank(await run(lines, <String>{'vo:g2.a'}));
        expect(server.requests.length, 3, reason: 'one more request, for לֹא');
        expect(second.ids.toSet(), <String>{'vo:g1.a', 'vo:g1.b', 'vo:g2.a', 'vo:g2.b'});
        expect(utf8.decode(second.clip('vo:g2.a')!.mp3), 'mp3:לֹא');
        // Run again: nothing is sent, nothing changes.
        await run(lines, <String>{'vo:g2.a'});
        expect(server.requests.length, 3);
      },
    );

    test('a run that stops half way is resumed without paying for what was made', () async {
      server.failAfter = 1;
      await expectLater(
        run(lines, <String>{'vo:g1.a', 'vo:g1.b', 'vo:g2.a'}),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(ClipLedger(work).hashes().keys, <String>['g1.a'], reason: 'the one clip that was said is kept');
      final FakeEleven again = FakeEleven();
      await generateVoicePack(
        characterId: 'nitzi',
        lines: lines,
        synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: again.client),
        profile: _v4,
        key: key,
        workDir: work,
        scope: <String>{'vo:g1.a', 'vo:g1.b', 'vo:g2.a'},
      );
      expect(again.requests.length, 2, reason: 'g1.b and g2.a only');
    });

    test('a new line with the text of a clip an earlier run made for another line copies it', () async {
      await run(const <SpokenLine>[SpokenLine('vo:g1.a', 'שָׁלוֹם')], null);
      final VoiceBank later = await bank(
        await run(const <SpokenLine>[SpokenLine('vo:g9.z', 'שָׁלוֹם')], null),
      );
      expect(server.requests.length, 1, reason: 'the second run sent nothing');
      expect(utf8.decode(later.clip('vo:g9.z')!.mp3), 'mp3:שָׁלוֹם');
    });

    test('without a scope the run is what it always was: every line, in one pack', () async {
      final VoiceBank all = await bank(await run(lines, null));
      expect(all.length, 4);
      expect(server.requests.length, 3);
    });
  });

  group('verify', () {
    late FakeEleven server;
    late Directory work;
    setUp(() {
      server = FakeEleven();
      work = _temp('nn_verify_');
    });
    tearDown(() => _drop(work));

    const List<(SpokenLine, String)> lines = <(SpokenLine, String)>[
      (SpokenLine('vo:a.one', 'שָׁלוֹם'), 'first'),
      (SpokenLine('vo:a.two', 'כֵּן'), 'first'),
      (SpokenLine('vo:b.one', 'לֹא'), 'second'),
    ];

    Future<void> voice(List<(SpokenLine, String)> which) => generateVoicePack(
      characterId: 'nitzi',
      lines: <SpokenLine>[for (final (SpokenLine l, String _) in which) l],
      synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: server.client),
      profile: _v4,
      key: key,
      workDir: work,
    );

    VerifyReport check({
      List<(SpokenLine, String)> which = lines,
      int minBytes = 1,
      List<String> unapproved = const <String>[],
    }) => verifyClips(workDir: work, profile: _v4, lines: which, unapproved: unapproved, minBytes: minBytes);

    test('a group whose clips are all there, with cues and the right hash, is complete', () async {
      await voice(lines);
      final VerifyReport r = check();
      expect(r.ok, isTrue);
      expect(r.describe(), contains('first: 2 of 2 clips are as the text says'));
      expect(r.describe(), contains('All 3 clips are there and match their text.'));
    });

    test(
      'a clip that was never made, one without cues, and one made from another text are each named',
      () async {
        await voice(lines.sublist(0, 2));
        File('${work.path}${Platform.pathSeparator}cue.a.two.json').deleteSync();
        final VerifyReport r = check(
          which: <(SpokenLine, String)>[...lines, (const SpokenLine('vo:a.one', 'שלום אחר'), 'first')],
        );
        expect(r.ok, isFalse);
        expect(r.faults['vo:b.one'], ClipFault.missing);
        expect(r.faults['vo:a.two'], ClipFault.missing, reason: 'no mouth cues is a clip the app cannot use');
        expect(r.faults['vo:a.one'], ClipFault.changed);
        final String text = r.describe();
        expect(text, contains('vo:b.one: missing'));
        expect(text, contains('made from another text or setting'));
        expect(text, contains('clips need attention'));
      },
    );

    test('a clip under 2 KB is not a clip, and a changed model or setting is a changed clip', () async {
      await voice(lines);
      expect(check(minBytes: minClipBytes).faults.values.toSet(), <ClipFault>{ClipFault.empty});
      expect(minClipBytes, 2048);
      const VoiceProfile other = VoiceProfile(
        voiceId: 'VoiceXyz0123',
        modelId: 'eleven_v4_turbo',
        outputFormat: 'mp3_44100_64',
        settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
      );
      final VerifyReport r = verifyClips(workDir: work, profile: other, lines: lines, minBytes: 1);
      expect(r.faults.values.toSet(), <ClipFault>{ClipFault.changed});
    });

    test('lines not approved yet are listed and not checked', () async {
      await voice(lines.sublist(0, 2));
      final VerifyReport r = check(which: lines.sublist(0, 2), unapproved: <String>['vo:b.one']);
      expect(r.ok, isTrue);
      expect(r.describe(), contains('1 lines are not approved yet and were not checked'));
    });
  });

  group('a pack that does not fit, and building the pack again from the saved clips', () {
    late Directory work;
    setUp(() => work = _temp('nn_repack_'));
    tearDown(() => _drop(work));

    const List<SpokenLine> two = <SpokenLine>[
      SpokenLine('vo:a.one', 'שָׁלוֹם'),
      SpokenLine('vo:a.two', 'כֵּן'),
    ];
    const List<SpokenLine> five = <SpokenLine>[
      SpokenLine('vo:a.one', 'שָׁלוֹם'),
      SpokenLine('vo:a.two', 'כֵּן'),
      SpokenLine('vo:a.three', 'לֹא'),
      SpokenLine('vo:a.four', 'אוּלַי'),
      SpokenLine('vo:a.five', 'תּוֹדָה'),
    ];

    test('too many bytes is said in plain words before anything is signed, and every clip is kept', () async {
      await expectLater(
        generateVoicePack(
          characterId: 'nitzi',
          lines: five,
          synth: _BigVoice(),
          profile: _v4,
          key: key,
          workDir: work,
        ),
        throwsA(
          isA<BuildFailed>()
              .having((BuildFailed e) => e.reason, 'message', contains('add up to 75.0 MB'))
              .having((BuildFailed e) => e.reason, 'message', contains('at most 64.0 MB'))
              .having((BuildFailed e) => e.reason, 'message', contains('Nothing was signed'))
              .having((BuildFailed e) => e.reason, 'message', contains('clips in the work folder are kept')),
        ),
      );
      expect(ClipLedger(work).hashes().keys, containsAll(<String>['a.one', 'a.five']));
      expect(File('${work.path}${Platform.pathSeparator}vo.a.five.mp3').existsSync(), isTrue);
      expect(Directory('${normalisedFolder(work)}.pack-stage').existsSync(), isFalse);
    });

    test(
      'the pack of what fits is then built from the saved clips with a voice that refuses to say anything',
      () async {
        await expectLater(
          generateVoicePack(
            characterId: 'nitzi',
            lines: five,
            synth: _BigVoice(),
            profile: _v4,
            key: key,
            workDir: work,
          ),
          throwsA(isA<BuildFailed>()),
        );
        final BuiltPack built = await generateVoicePack(
          characterId: 'nitzi',
          lines: five.sublist(0, 3),
          synth: const SilentVoice(),
          profile: _v4,
          key: key,
          workDir: work,
          scope: <String>{},
        );
        final VoiceBank bank = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
        expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:a.two', 'vo:a.three'});
      },
    );

    test('rebuilding the pack from the clips gives the same bytes and sends nothing; a line with no clip is left out', () async {
      final FakeEleven server = FakeEleven();
      final BuiltPack first = await generateVoicePack(
        characterId: 'hero-son',
        lines: two,
        synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: server.client),
        profile: _v4,
        key: key,
        workDir: work,
        version: '2.0.0',
      );
      expect(server.requests.length, 2);
      final BuiltPack again = await generateVoicePack(
        characterId: 'hero-son',
        lines: <SpokenLine>[...two, const SpokenLine('vo:a.three', 'לֹא')],
        synth: const SilentVoice(),
        profile: _v4,
        key: key,
        workDir: work,
        version: '2.0.0',
        scope: <String>{},
      );
      expect(server.requests.length, 2, reason: 'the voice was never asked');
      expect(again.bytes, first.bytes);
      final VoiceBank bank = VoiceBank.fromPack(await verifyPack(again.bytes, publicKey: key.publicKey));
      expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:a.two'});
    });

    test('the plan expects the size of the pack, and warns before the owner pays for a pack that cannot be built', () {
      final VoicePlan small = planVoices(
        <String, VoiceProfile>{'nitzi': _v4},
        const <SpokenLine>[SpokenLine('vo:a.one', 'שלום'), SpokenLine('vo:a.two', 'שלום')],
      );
      expect(small.estimatedPackBytes('nitzi'), 2 * cueBytesPerLine + 4 * soundBytesPerCharacter);
      expect(small.describe(0.08), contains('Expected size of the pack of nitzi: about 0 MB'));
      final VoicePlan huge = planVoices(
        <String, VoiceProfile>{'nitzi': _v4},
        <SpokenLine>[SpokenLine('vo:a.one', 'א' * 100000)],
      );
      final String text = huge.describe(0.08);
      expect(
        text,
        contains('WARNING, the pack of nitzi would be about 65 MB and the app reads 64 MB at most'),
      );
      expect(text, contains('`pack` builds it afterwards, free'));
    });
  });

  group('the batch options in the source', () {
    final String cli = File('tool/voice_gen.dart').readAsStringSync();
    final String groups = File('tool/voice_groups_lib.dart').readAsStringSync();

    test(
      'a paid run still plans, prints and asks for the typed count; the batch is chosen before the gate only',
      () {
        final String generate = cli.substring(
          cli.indexOf('Future<void> _generate('),
          cli.indexOf('/// What `plan-lang` and `generate-lang` both need'),
        );
        expect(generate.indexOf('requireTerminal('), lessThan(generate.indexOf('_batch(')));
        expect(generate, contains('generateGated('));
        expect(generate, contains('scope: batch?.scope'));
        expect(generate, isNot(contains('synth()')));
        expect(cli, contains("'verify'"));
        expect(groups, isNot(contains('synth')));
        expect(groups, isNot(contains('Platform.environment')));
      },
    );

    test('a rejected pack is reported with its stage and reason, and the saved clips are pointed to', () {
      expect(cli, contains('on PackRejected catch (e)'));
      expect(cli, contains('the pack was rejected by the app'));
      expect(cli, contains("case 'pack':"));
      final int start = cli.indexOf('Future<void> _pack(');
      final String pack = cli.substring(start, cli.indexOf('/// Free: every group of the manifest', start));
      expect(pack, contains('const SilentVoice()'));
      expect(pack, contains('scope: <String>{}'));
      expect(pack, isNot(contains('_eleven')));
      expect(pack, isNot(contains('requireTyped')));
    });

    test('verify and groups are free: they never read a key or ask for a voice', () {
      for (final String name in <String>['void _groups(', 'void _verify(', 'void _verifyLang(']) {
        final int start = cli.indexOf(name);
        final String body = cli.substring(start, cli.indexOf(RegExp(r'\r?\n\}'), start));
        expect(body, isNot(contains('_eleven')), reason: name);
        expect(body, isNot(contains('readKeyFile')), reason: name);
        expect(body, isNot(contains('requireTyped')), reason: name);
      }
    });
  });
}
