import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

Matcher _buildFails([String? part]) => throwsA(
  isA<BuildFailed>().having(
    (BuildFailed e) => e.toString(),
    'message',
    part == null ? isNotEmpty : contains(part),
  ),
);

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('nn_builder_'));
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may hold a file for a moment.
    }
  });

  Directory source([String version = '1.0.0']) =>
      writeSampleSource(Directory('${tmp.path}${Platform.pathSeparator}src'), version: version);
  File inSource(String name) => File('${tmp.path}${Platform.pathSeparator}src${Platform.pathSeparator}$name');

  group('keys', () {
    test('keygen writes a key file outside the repo and the public half matches it', () async {
      final String path = '${tmp.path}${Platform.pathSeparator}keys${Platform.pathSeparator}pack-signing.key';
      final PackKey key = await generateKeyFile(path);
      final PackKey back = readKeyFile(path);
      expect(hex(back.publicKey), hex(key.publicKey));
      expect(back.seed, key.seed);
      expect(key.publicKey, hasLength(32));
      // The same key signs and the public half verifies.
      final BuiltPack built = await buildSamplePack(back);
      expect((await verifyPack(built.bytes, publicKey: key.publicKey)).id, 'sample-pack');
    });

    test('keygen refuses a path inside the repository', () async {
      final String inside = '${Directory.current.path}${Platform.pathSeparator}should_not_exist.key';
      await expectLater(generateKeyFile(inside), _buildFails('inside a git working tree'));
      expect(File(inside).existsSync(), isFalse);
      await expectLater(
        generateKeyFile(
          '${Directory.current.path}${Platform.pathSeparator}..${Platform.pathSeparator}design${Platform.pathSeparator}x.key',
        ),
        _buildFails('git working tree'),
      );
    });

    test('keygen never overwrites an existing key', () async {
      final String path = '${tmp.path}${Platform.pathSeparator}k.key';
      await generateKeyFile(path);
      final String before = File(path).readAsStringSync();
      await expectLater(generateKeyFile(path), _buildFails('already exists'));
      expect(File(path).readAsStringSync(), before);
    });

    test('a damaged or foreign key file is refused', () {
      final File f = File('${tmp.path}${Platform.pathSeparator}k.key')..writeAsStringSync('hello\n');
      expect(() => readKeyFile(f.path), _buildFails('not a pack-signing key'));
      f.writeAsStringSync('$keyFileHeader\npublic: 00\nseed: 00\n');
      expect(() => readKeyFile(f.path), _buildFails('damaged'));
      expect(() => readKeyFile('${tmp.path}${Platform.pathSeparator}nope.key'), _buildFails('no key file'));
    });

    test('a key file whose public half does not match its seed is refused', () async {
      final PackKey a = await newTestKey();
      final PackKey b = await newTestKey();
      expect(
        () => buildPack(source(), PackKey(seed: a.seed, publicKey: b.publicKey)),
        throwsA(isA<BuildFailed>()),
      );
    });
  });

  group('building', () {
    test('building twice gives identical bytes; changing one source byte changes them', () async {
      final PackKey key = await newTestKey();
      final BuiltPack a = await buildPack(source(), key);
      final BuiltPack b = await buildPack(source(), key);
      expect(a.bytes, b.bytes);
      expect(a.manifestSha256, b.manifestSha256);
      expect(a.fileName, 'sample-pack-1.0.0.nnpack');

      final File svg = inSource('jar.svg');
      svg.writeAsStringSync('${svg.readAsStringSync()} ');
      final BuiltPack c = await buildPack(Directory(svg.parent.path), key);
      expect(c.bytes, isNot(a.bytes));
      expect(c.manifestSha256, isNot(a.manifestSha256));
    });

    test('line endings do not change the pack (Windows checkouts use CRLF)', () async {
      final PackKey key = await newTestKey();
      final BuiltPack lf = await buildPack(source(), key);
      for (final String name in <String>['jar.svg', 'lesson.butterflies.json']) {
        final File f = inSource(name);
        f.writeAsStringSync(f.readAsStringSync().replaceAll('\n', '\r\n'));
      }
      final BuiltPack crlf = await buildPack(Directory(inSource('pack.json').parent.path), key);
      expect(crlf.bytes, lf.bytes);
    });

    test(
      'the manifest lists every file with its hash, sorted, and works out the template versions',
      () async {
        final PackKey key = await newTestKey();
        final VerifiedPack v = await verifyPack(
          (await buildPack(source(), key)).bytes,
          publicKey: key.publicKey,
        );
        final List<Map<String, Object?>> files = <Map<String, Object?>>[
          for (final Object? f in v.manifest['files']! as List<Object?>) f! as Map<String, Object?>,
        ];
        final List<String> names = <String>[for (final Map<String, Object?> f in files) f['name']! as String];
        expect(names, <String>[...names]..sort());
        expect(names, isNot(contains('manifest.json')));
        expect(names, isNot(contains('pack.json')));
        for (final Map<String, Object?> f in files) {
          expect(f['sha256'], sha256Hex(v.files[f['name']]!));
          expect(f['size'], v.files[f['name']]!.length);
        }
        expect(v.manifest['templates'], <String, Object?>{
          'count_tap': '1.0',
          'give_n': '1.0',
          'tap_answer': '1.0',
        });
        final Map<String, Object?> entries = v.manifest['entries']! as Map<String, Object?>;
        expect(entries['activities'], <String>['count.butterflies.3', 'give.three.jar', 'pick.red.flower']);
        expect(entries['lessons'], <String>['butterflies']);
      },
    );

    test('a different version gives a different file name and manifest', () async {
      final PackKey key = await newTestKey();
      final BuiltPack v1 = await buildPack(source(), key);
      tmp.deleteSync(recursive: true);
      tmp.createSync();
      final BuiltPack v2 = await buildPack(source('1.1.0'), key);
      expect(v2.fileName, 'sample-pack-1.1.0.nnpack');
      expect(v2.manifestSha256, isNot(v1.manifestSha256));
    });
  });

  group('the builder refuses to sign a bad source', () {
    late PackKey key;
    setUp(() async => key = await newTestKey());

    test('a source folder that does not exist, or has no pack.json', () async {
      await expectLater(
        buildPack(Directory('${tmp.path}${Platform.pathSeparator}nope'), key),
        _buildFails('no source folder'),
      );
      final Directory empty = Directory('${tmp.path}${Platform.pathSeparator}empty')..createSync();
      await expectLater(buildPack(empty, key), _buildFails('no pack.json'));
    });

    test('a pack.json that breaks its schema, with the path', () async {
      source();
      inSource('pack.json').writeAsStringSync(
        jsonEncode(<String, Object?>{'schema': 'pack-source/v1', 'id': 'X', 'version': '1'}),
      );
      await expectLater(
        buildPack(Directory(inSource('pack.json').parent.path), key),
        _buildFails('pack.json › id'),
      );
    });

    test('a content problem is reported with its path and nothing is signed', () async {
      source();
      final File f = inSource('activity.count.butterflies.3.json');
      final Map<String, Object?> doc = jsonDecode(f.readAsStringSync())! as Map<String, Object?>;
      ((doc['scene']! as Map<String, Object?>)['objects']! as Map<String, Object?>)['count'] = 4;
      f.writeAsStringSync(jsonEncode(doc));
      await expectLater(
        buildPack(Directory(f.parent.path), key),
        _buildFails(
          'activity.count.butterflies.3.json › answer.correct: the correct option must show the number of objects (4)',
        ),
      );
    });

    test('a template version newer than this builder supports', () async {
      source();
      final File f = inSource('activity.pick.red.flower.json');
      final Map<String, Object?> doc = jsonDecode(f.readAsStringSync())! as Map<String, Object?>;
      doc['templateVersion'] = '2.0';
      f.writeAsStringSync(jsonEncode(doc));
      await expectLater(
        buildPack(Directory(f.parent.path), key),
        _buildFails('newer than this builder supports'),
      );
    });

    test('a file that is not JSON, a folder, an unsafe name, an unused file', () async {
      source();
      inSource('lesson.butterflies.json').writeAsStringSync('{ not json');
      await expectLater(
        buildPack(Directory(inSource('pack.json').parent.path), key),
        _buildFails('not valid JSON'),
      );

      source();
      Directory('${inSource('pack.json').parent.path}${Platform.pathSeparator}sub').createSync();
      await expectLater(
        buildPack(Directory(inSource('pack.json').parent.path), key),
        _buildFails('is a folder or link'),
      );
      Directory('${inSource('pack.json').parent.path}${Platform.pathSeparator}sub').deleteSync();

      File('${inSource('pack.json').parent.path}${Platform.pathSeparator}.secret').writeAsStringSync('x');
      await expectLater(
        buildPack(Directory(inSource('pack.json').parent.path), key),
        _buildFails('not a plain file name'),
      );
      File('${inSource('pack.json').parent.path}${Platform.pathSeparator}.secret').deleteSync();

      File('${inSource('pack.json').parent.path}${Platform.pathSeparator}orphan.svg')
          .writeAsStringSync('<svg/>');
      await expectLater(
        buildPack(Directory(inSource('pack.json').parent.path), key),
        _buildFails('is not used by any asset'),
      );
    });
  });

  group('damaged copies for the phone', () {
    test('every variant is refused by the same check the app runs', () async {
      final PackKey key = await newTestKey();
      final BuiltPack built = await buildPack(source(), key);
      await verifyPack(built.bytes, publicKey: key.publicKey); // the original is fine
      final Map<String, Uint8List> variants = damagedVariants(built.bytes);
      expect(
        variants.keys,
        containsAll(<String>[
          'damaged-picture.nnpack',
          'damaged-manifest.nnpack',
          'damaged-signature.nnpack',
          'damaged-one-byte.nnpack',
          'truncated.nnpack',
        ]),
      );
      for (final MapEntry<String, Uint8List> v in variants.entries) {
        await expectLater(
          verifyPack(v.value, publicKey: key.publicKey),
          throwsA(isA<PackRejected>()),
          reason: v.key,
        );
      }
    });
  });

  group('JSON Schema files', () {
    test('there is one per document kind and each is current (run `dart run tool/pack_builder.dart schema` if not)', () {
      final Map<String, String> files = renderSchemas();
      expect(
        files.keys,
        containsAll(<String>[
          'manifest.schema.json',
          'activity.count_tap.schema.json',
          'pack-source.schema.json',
        ]),
      );
      for (final MapEntry<String, String> e in files.entries) {
        final File f = File('../content/schemas/${e.key}');
        expect(f.existsSync(), isTrue, reason: '${f.path} is missing');
        expect(f.readAsStringSync().replaceAll('\r\n', '\n'), e.value, reason: '${e.key} is out of date');
      }
    });

    test('the files are standard JSON Schema: they carry the dialect and the same closed objects', () {
      for (final String text in renderSchemas().values) {
        final Map<String, Object?> js = jsonDecode(text)! as Map<String, Object?>;
        expect(js[r'$schema'], contains('2020-12'));
        expect(js['additionalProperties'], false);
      }
    });
  });
}
