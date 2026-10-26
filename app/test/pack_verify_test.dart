import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

Matcher _rejectedAt(String stage, [String? reason]) => throwsA(
  isA<PackRejected>()
      .having((PackRejected e) => e.stage, 'stage', stage)
      .having((PackRejected e) => e.reason, 'reason', reason == null ? isNotEmpty : contains(reason)),
);

void main() {
  late PackKey key;
  late PackKey otherKey;
  late Uint8List pack;

  setUpAll(() async {
    key = await newTestKey();
    otherKey = await newTestKey();
    pack = (await buildSamplePack(key)).bytes;
  });

  test('a genuine pack is accepted and its documents are parsed', () async {
    final VerifiedPack v = await verifyWith(pack, key);
    expect(v.id, 'sample-pack');
    expect(v.version, '1.0.0');
    expect(
      v.docs.keys,
      containsAll(<String>['lesson.butterflies.json', 'activity.count.butterflies.3.json']),
    );
    expect(v.files.keys, isNot(contains('manifest.json')));
    expect(v.manifestSha256, hasLength(64));
    expect(v.manifestSha256, sha256Hex(v.manifestBytes));
  });

  group('the signature comes first', () {
    test('a pack signed by another key is refused, and no JSON is parsed', () async {
      final DecodeSpy spy = DecodeSpy();
      await expectLater(verifyWith(pack, otherKey, spy: spy), _rejectedAt('signature'));
      expect(spy.seen, isEmpty);
    });

    test('a changed signature is refused, and no JSON is parsed', () async {
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> e) => e[signatureName]![10] ^= 1);
      final DecodeSpy spy = DecodeSpy();
      await expectLater(verifyWith(bad, key, spy: spy), _rejectedAt('signature'));
      expect(spy.seen, isEmpty);
    });

    test('a changed manifest is refused, and no JSON is parsed', () async {
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> e) => e[manifestName]![20] ^= 1);
      final DecodeSpy spy = DecodeSpy();
      await expectLater(verifyWith(bad, key, spy: spy), _rejectedAt('signature'));
      expect(spy.seen, isEmpty);
    });

    test('a signature of the wrong length is refused', () async {
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> e) => e[signatureName] = Uint8List(63));
      await expectLater(verifyWith(bad, key), _rejectedAt('signature', 'length'));
    });

    test('the signature covers a label, so a bare signature over the manifest does not count', () async {
      final Map<String, Uint8List> e = unzip(pack);
      final Uint8List bare = Uint8List.fromList((await ed25519Sign(key, e[manifestName]!)));
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> m) => m[signatureName] = bare);
      await expectLater(verifyWith(bad, key), _rejectedAt('signature'));
    });

    test('a pack with no manifest or no signature is refused', () async {
      await expectLater(
        verifyWith(rezip(pack, (Map<String, Uint8List> e) => e.remove(manifestName)), key),
        _rejectedAt('zip', 'missing'),
      );
      await expectLater(
        verifyWith(rezip(pack, (Map<String, Uint8List> e) => e.remove(signatureName)), key),
        _rejectedAt('zip', 'missing'),
      );
    });
  });

  group('then every file is proven before any of them is read', () {
    test(
      'a changed activity (the zip is valid, the manifest is signed) is refused and never parsed',
      () async {
        final Uint8List bad = rezip(
          pack,
          (Map<String, Uint8List> e) => e['activity.pick.red.flower.json']![5] ^= 1,
        );
        final DecodeSpy spy = DecodeSpy();
        await expectLater(
          verifyWith(bad, key, spy: spy),
          _rejectedAt('files', 'activity.pick.red.flower.json'),
        );
        expect(spy.seen, hasLength(1)); // only the manifest, which the signature vouches for
        expect(spy.seen.single, contains('"schema": "manifest/v1"'));
      },
    );

    test('a changed picture is refused', () async {
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> e) => e['jar.svg']![3] ^= 1);
      await expectLater(verifyWith(bad, key), _rejectedAt('files', 'jar.svg'));
    });

    test('a file of the same hash but another size cannot exist; a wrong size is refused', () async {
      final Uint8List bad = await forge(
        key,
        pack,
        fixHashes: false,
        files: (Map<String, Uint8List> f) => f['jar.svg'] = Uint8List.fromList(<int>[...f['jar.svg']!, 0x20]),
      );
      await expectLater(verifyWith(bad, key), _rejectedAt('files', 'size'));
    });

    test('a file missing from the pack is refused', () async {
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> e) => e.remove('meadow.svg'));
      await expectLater(verifyWith(bad, key), _rejectedAt('files', 'meadow.svg'));
    });

    test('an extra file is refused', () async {
      final Uint8List bad = rezip(pack, (Map<String, Uint8List> e) => e['extra.bin'] = Uint8List(4));
      await expectLater(verifyWith(bad, key), _rejectedAt('files', 'extra.bin'));
    });
  });

  group('a pack signed by the right key but wrong in content is refused too', () {
    test('forging with the real key and unchanged content still passes (the helper is sound)', () async {
      final Uint8List same = await forge(key, pack);
      expect((await verifyWith(same, key)).id, 'sample-pack');
    });

    test('a broken activity', () async {
      final Uint8List bad = await forge(
        key,
        pack,
        files: (Map<String, Uint8List> f) {
          final Map<String, Object?> doc =
              jsonDecode(utf8.decode(f['activity.count.butterflies.3.json']!))! as Map<String, Object?>;
          (doc['scene']! as Map<String, Object?>)['extra'] = 1;
          f['activity.count.butterflies.3.json'] = Uint8List.fromList(utf8.encode(jsonEncode(doc)));
        },
      );
      await expectLater(
        verifyWith(bad, key),
        throwsA(
          isA<PackRejected>()
              .having((PackRejected e) => e.stage, 'stage', 'content')
              .having(
                (PackRejected e) => e.problems.map((p) => p.toString()),
                'problems',
                contains(contains('scene: unknown field "extra"')),
              ),
        ),
      );
    });

    test('JSON nested far too deeply is refused without being parsed', () async {
      final DecodeSpy spy = DecodeSpy();
      final Uint8List bad = await forge(
        key,
        pack,
        files: (Map<String, Uint8List> f) {
          f['skill.NUM-A-04.json'] = Uint8List.fromList(utf8.encode('${'[' * 100000}${']' * 100000}'));
        },
      );
      await expectLater(verifyWith(bad, key, spy: spy), _rejectedAt('content', 'nested'));
      expect(
        spy.seen.any((String s) => s.startsWith('[[[')),
        isFalse,
      ); // the deep file never reached the parser
    });

    test('a deep object in the manifest itself is refused', () async {
      final Map<String, Uint8List> parts = unzip(pack);
      final Uint8List deep = Uint8List.fromList(utf8.encode('${'{"a":' * 100}1${'}' * 100}'));
      final Uint8List bad = await resign(key, deep, <String, Uint8List>{
        for (final MapEntry<String, Uint8List> e in parts.entries)
          if (e.key != manifestName && e.key != signatureName) e.key: e.value,
      });
      await expectLater(verifyWith(bad, key), _rejectedAt('manifest', 'nested'));
    });

    test('text that is not UTF-8, or not JSON, is refused', () async {
      final Uint8List latin = await forge(
        key,
        pack,
        files: (Map<String, Uint8List> f) =>
            f['skill.NUM-A-04.json'] = Uint8List.fromList(<int>[0xFF, 0xFE, 0x7B, 0x7D]),
      );
      await expectLater(verifyWith(latin, key), _rejectedAt('content', 'UTF-8'));
      final Uint8List notJson = await forge(
        key,
        pack,
        files: (Map<String, Uint8List> f) =>
            f['skill.NUM-A-04.json'] = Uint8List.fromList(utf8.encode('{"a": ')),
      );
      await expectLater(verifyWith(notJson, key), _rejectedAt('content', 'not valid JSON'));
    });

    test('a manifest that breaks its schema is refused with the path', () async {
      final Uint8List bad = await forge(
        key,
        pack,
        manifest: (Map<String, Object?> m) => m['version'] = 'one',
      );
      await expectLater(
        verifyWith(bad, key),
        throwsA(
          isA<PackRejected>().having((PackRejected e) => e.problems.join(), 'problems', contains('version')),
        ),
      );
    });

    test('a JSON top level that is not an object is refused', () async {
      final Map<String, Uint8List> parts = unzip(pack)
        ..remove(manifestName)
        ..remove(signatureName);
      final Uint8List bad = await resign(key, Uint8List.fromList(utf8.encode('[1,2,3]')), parts);
      await expectLater(verifyWith(bad, key), _rejectedAt('manifest', 'not an object'));
    });
  });

  test(
    'changing any single byte of a real pack is refused (sampled here; the installer test covers every byte)',
    () async {
      int tried = 0;
      for (int i = 0; i < pack.length; i += 13) {
        final Uint8List bad = Uint8List.fromList(pack)..[i] ^= 1;
        await expectLater(verifyWith(bad, key), throwsA(isA<PackRejected>()), reason: 'byte $i');
        tried++;
      }
      expect(tried, greaterThan(100));
    },
  );
}
