import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/zip_store.dart';

import 'support/zip_store_reference.dart';

Uint8List _bytes(String s) => Uint8List.fromList(s.codeUnits);

List<ZipEntry> _sample() => <ZipEntry>[
  ZipEntry('manifest.json', _bytes('{"a":1}')),
  ZipEntry('aaaa.txt', _bytes('hello')),
  ZipEntry('bbbb.bin', Uint8List.fromList(<int>[0, 1, 2, 3, 255])),
  ZipEntry('empty.txt', Uint8List(0)),
];

Matcher _refused([String? part]) => throwsA(
  isA<ZipException>().having(
    (ZipException e) => e.reason,
    'reason',
    part == null ? isNotEmpty : contains(part),
  ),
);

void _u16(Uint8List z, int at, int v) => ByteData.sublistView(z).setUint16(at, v, Endian.little);
void _u32(Uint8List z, int at, int v) => ByteData.sublistView(z).setUint32(at, v, Endian.little);

/// Position of the first central-directory entry (the writer puts the directory right after the files).
int _directoryStart(Uint8List z) => ByteData.sublistView(z).getUint32(z.length - 22 + 16, Endian.little);

/// Replaces every occurrence of [from] by [to] (same length), in the local and the central header.
Uint8List _rename(Uint8List z, String from, String to) {
  assert(from.length == to.length);
  final Uint8List out = Uint8List.fromList(z);
  int hits = 0;
  for (int i = 0; i + from.length <= out.length; i++) {
    bool match = true;
    for (int k = 0; k < from.length; k++) {
      if (out[i + k] != from.codeUnitAt(k)) {
        match = false;
        break;
      }
    }
    if (match) {
      out.setRange(i, i + to.length, to.codeUnits);
      hits++;
    }
  }
  expect(hits, greaterThanOrEqualTo(2), reason: 'the name should be in both headers');
  return out;
}

/// What [read] made of [bytes]: each entry's name, data and place in [bytes], or the reason it refused.
Object _outcome(List<ZipEntry> Function(Uint8List) read, Uint8List bytes) {
  try {
    return <Object>[
      for (final ZipEntry e in read(bytes))
        <Object>[e.name, e.data, e.data.offsetInBytes, identical(e.data.buffer, bytes.buffer)],
    ];
  } on ZipException catch (e) {
    return 'refused: ${e.reason}';
  }
}

Uint8List _random(Random rnd, int length) =>
    Uint8List.fromList(<int>[for (int i = 0; i < length; i++) rnd.nextInt(256)]);

/// The bundled starter pack, whatever its version.
Uint8List _realPack() => File(
  Directory('assets/packs')
      .listSync()
      .whereType<File>()
      .map((File f) => f.path)
      .singleWhere((String p) => RegExp(r'starter-[0-9.]+\.nnpack$').hasMatch(p)),
).readAsBytesSync();

void main() {
  group('writing and reading', () {
    test('a zip reads back to what was written', () {
      final List<ZipEntry> back = readStoredZip(writeStoredZip(_sample()));
      expect(
        <String>[for (final ZipEntry e in back) e.name],
        <String>['aaaa.txt', 'bbbb.bin', 'empty.txt', 'manifest.json'],
      );
      expect(back.firstWhere((ZipEntry e) => e.name == 'bbbb.bin').data, <int>[0, 1, 2, 3, 255]);
      expect(back.firstWhere((ZipEntry e) => e.name == 'empty.txt').data, isEmpty);
    });

    test('the same entries in any order give the same bytes', () {
      final Uint8List a = writeStoredZip(_sample());
      final Uint8List b = writeStoredZip(_sample().reversed.toList());
      expect(a, b);
    });

    test('the writer refuses unsafe and repeated names', () {
      for (final String name in <String>[
        '../x',
        'a/b',
        'a\\b',
        '.hidden',
        'C:x',
        'nul.txt',
        'COM1',
        'a..b',
        'end.',
        '',
        'a b',
        'é.txt',
      ]) {
        expect(
          () => writeStoredZip(<ZipEntry>[ZipEntry(name, Uint8List(1))]),
          throwsArgumentError,
          reason: name,
        );
      }
      expect(
        () => writeStoredZip(<ZipEntry>[ZipEntry('a.txt', Uint8List(1)), ZipEntry('A.TXT', Uint8List(1))]),
        throwsArgumentError,
      );
    });

    test('crc32 matches the standard check value', () {
      expect(crc32(_bytes('123456789')), 0xCBF43926);
    });
  });

  group('the reader refuses what the writer would never make', () {
    final Uint8List good = writeStoredZip(_sample());

    test('every possible change of any single byte is refused (all 255 other values)', () {
      // Small zip, so this is exhaustive: no byte of the container can change unnoticed.
      for (int i = 0; i < good.length; i++) {
        for (int v = 0; v < 256; v++) {
          if (v == good[i]) {
            continue;
          }
          final Uint8List bad = Uint8List.fromList(good)..[i] = v;
          expect(() => readStoredZip(bad), _refused(), reason: 'byte $i changed to $v was accepted');
        }
      }
    });

    test('every truncation is refused', () {
      for (int n = 0; n < good.length; n++) {
        expect(() => readStoredZip(Uint8List.sublistView(good, 0, n)), _refused(), reason: 'cut at $n');
      }
    });

    test('bytes added at either end are refused', () {
      expect(() => readStoredZip(Uint8List.fromList(<int>[...good, 0])), _refused());
      expect(() => readStoredZip(Uint8List.fromList(<int>[0, ...good])), _refused());
    });

    test('a compressed entry is refused', () {
      final Uint8List z = Uint8List.fromList(good);
      _u16(z, _directoryStart(z) + 10, 8);
      expect(() => readStoredZip(z), _refused('stored'));
    });

    test('encryption or data-descriptor flags are refused', () {
      final Uint8List z = Uint8List.fromList(good);
      _u16(z, _directoryStart(z) + 8, 1);
      expect(() => readStoredZip(z), _refused('flags'));
      final Uint8List d = Uint8List.fromList(good);
      _u16(d, _directoryStart(d) + 8, 8);
      expect(() => readStoredZip(d), _refused('flags'));
    });

    test('an extra field or a comment is refused', () {
      final Uint8List z = Uint8List.fromList(good);
      _u16(z, _directoryStart(z) + 30, 4);
      expect(() => readStoredZip(z), _refused('extra'));
      final Uint8List c = Uint8List.fromList(good);
      _u16(c, c.length - 2, 3);
      expect(() => readStoredZip(c), _refused());
    });

    test('a zip64 marker or a multi-disk zip is refused', () {
      final Uint8List z = Uint8List.fromList(good);
      _u32(z, _directoryStart(z) + 24, 0xFFFFFFFF);
      _u32(z, _directoryStart(z) + 20, 0xFFFFFFFF);
      expect(() => readStoredZip(z), _refused());
      final Uint8List d = Uint8List.fromList(good);
      _u16(d, d.length - 22 + 4, 1);
      expect(() => readStoredZip(d), _refused('multi-disk'));
    });

    test('a size that claims more than the whole file is refused (zip bomb)', () {
      final Uint8List z = Uint8List.fromList(good);
      final int d = _directoryStart(z);
      _u32(z, d + 20, 0x7FFFFFFF);
      _u32(z, d + 24, 0x7FFFFFFF);
      expect(() => readStoredZip(z), _refused('too large'));
    });

    test('two entries that point at the same bytes are refused', () {
      final Uint8List z = Uint8List.fromList(good);
      final int d = _directoryStart(z);
      // Second central entry (name length 8 + 46): make it start where the first one does.
      final int second = d + 46 + 8;
      _u32(z, second + 42, 0);
      expect(() => readStoredZip(z), _refused('order'));
    });

    test('unsafe names are refused even when both headers agree', () {
      const List<(String, String)> cases = <(String, String)>[
        ('aaaa.txt', '../a.txt'),
        ('aaaa.txt', 'a/aa.txt'),
        ('aaaa.txt', 'a\\aa.txt'),
        ('aaaa.txt', '.aaa.txt'),
        ('aaaa.txt', 'aaaaaaa.'),
        ('aaaa.txt', 'a..a.txt'),
        ('aaaa.txt', 'aa a.txt'),
      ];
      for (final (String from, String to) in cases) {
        expect(() => readStoredZip(_rename(good, from, to)), _refused(), reason: to);
      }
      final Uint8List nul = writeStoredZip(<ZipEntry>[
        ZipEntry('abc.txt', Uint8List(1)),
        ZipEntry('x.txt', Uint8List(1)),
      ]);
      expect(() => readStoredZip(_rename(nul, 'abc.txt', 'nul.txt')), _refused('reserved'));
    });

    test('a name that is not ASCII is refused', () {
      final Uint8List z = Uint8List.fromList(good);
      for (int i = 0; i + 8 <= z.length; i++) {
        if (String.fromCharCodes(z, i, i + 8) == 'aaaa.txt') {
          z[i] = 0xC3;
        }
      }
      expect(() => readStoredZip(z), _refused());
    });

    test('two names that differ only in case are refused', () {
      final Uint8List z = writeStoredZip(<ZipEntry>[
        ZipEntry('aaaa.txt', Uint8List(1)),
        ZipEntry('aaab.txt', Uint8List(1)),
      ]);
      expect(() => readStoredZip(_rename(z, 'aaab.txt', 'AAAA.txt')), _refused());
    });

    test('more than 8,002 entries are refused', () {
      final Uint8List z = writeStoredZip(<ZipEntry>[
        for (int i = 0; i < 8003; i++) ZipEntry('f$i.bin', Uint8List(1)),
      ]);
      expect(() => readStoredZip(z), _refused('8003 entries'));
      final Uint8List ok = writeStoredZip(<ZipEntry>[
        for (int i = 0; i < 8002; i++) ZipEntry('f$i.bin', Uint8List(1)),
      ]);
      expect(readStoredZip(ok), hasLength(8002));
    });

    test('more than 64 MB of content is refused', () {
      final Uint8List block = Uint8List(1024 * 1024);
      final Uint8List z = writeStoredZip(<ZipEntry>[for (int i = 0; i < 65; i++) ZipEntry('f$i.bin', block)]);
      expect(() => readStoredZip(z), _refused('too large'));
    });

    test('a file larger than the limit is refused before it is looked at', () {
      expect(() => readStoredZip(Uint8List(ZipLimits.maxZipBytes + 1)), _refused('too large'));
    });

    test('an empty or tiny input is refused', () {
      expect(() => readStoredZip(Uint8List(0)), _refused());
      expect(() => readStoredZip(Uint8List(21)), _refused());
      expect(() => readStoredZip(Uint8List(22)), _refused());
    });
  });

  group('fuzz: nothing but a ZipException ever comes out', () {
    test('random garbage and random damage to a good zip', () {
      final Random rnd = Random(20261026);
      final Uint8List good = writeStoredZip(_sample());
      int refused = 0;
      for (int round = 0; round < 3000; round++) {
        final Uint8List input;
        switch (round % 3) {
          case 0:
            input = Uint8List.fromList(<int>[for (int i = 0; i < rnd.nextInt(200); i++) rnd.nextInt(256)]);
          case 1:
            input = Uint8List.fromList(good);
            for (int k = 0; k < 1 + rnd.nextInt(6); k++) {
              input[rnd.nextInt(input.length)] = rnd.nextInt(256);
            }
          default:
            input = Uint8List.fromList(
              good.sublist(0, rnd.nextInt(good.length)) + good.sublist(rnd.nextInt(good.length)),
            );
        }
        try {
          readStoredZip(input);
        } on ZipException {
          refused++;
        }
      }
      expect(refused, greaterThan(2900)); // the few that survive are the ones that changed nothing
    });
  });

  // B-12 made the CRC-32, the name rule and the canonical re-write faster. These prove the results did not
  // change: the code before is kept in support/zip_store_reference.dart as the oracle.
  group('the faster reader and writer give exactly the results of the code before them', () {
    test('crc32 gives the standard values', () {
      expect(crc32(Uint8List(0)), 0x00000000);
      expect(crc32(_bytes('a')), 0xE8B7BE43);
      expect(crc32(_bytes('abc')), 0x352441C2);
      expect(crc32(_bytes('message digest')), 0x20159D7F);
      expect(crc32(_bytes('123456789')), 0xCBF43926);
      expect(crc32(_bytes('The quick brown fox jumps over the lazy dog')), 0x414FA339);
    });

    test(
      'crc32 equals the bytewise CRC-32 for every length up to 300 at every alignment, and on large buffers',
      () {
        final Random rnd = Random(20261029);
        for (int length = 0; length <= 300; length++) {
          for (int offset = 0; offset < 8; offset++) {
            final Uint8List data = Uint8List.sublistView(
              _random(rnd, offset + length + 3),
              offset,
              offset + length,
            );
            expect(crc32(data), referenceCrc32(data), reason: 'length $length at offset $offset');
          }
        }
        for (int round = 0; round < 40; round++) {
          final Uint8List data = _random(rnd, rnd.nextInt(200000));
          expect(crc32(data), referenceCrc32(data), reason: 'round $round, ${data.length} bytes');
        }
        final Uint8List ones = Uint8List(4096)..fillRange(0, 4096, 0xFF);
        expect(crc32(ones), referenceCrc32(ones));
      },
    );

    test('every single changed bit of a buffer changes its CRC-32, as before', () {
      final Uint8List data = _random(Random(7), 1031);
      final int good = crc32(data);
      for (int bit = 0; bit < data.length * 8; bit++) {
        data[bit >> 3] ^= 1 << (bit & 7);
        final int changed = crc32(data);
        expect(changed, isNot(good), reason: 'bit $bit');
        expect(changed, referenceCrc32(data), reason: 'bit $bit');
        data[bit >> 3] ^= 1 << (bit & 7);
      }
    });

    test('the name rule gives the same answer as the pattern it replaced', () {
      final Random rnd = Random(101);
      const String plain = 'aZ09._-';
      final List<String> names = <String>[
        for (int c = 0; c < 256; c++) String.fromCharCode(c),
        for (int c = 0; c < 256; c++) 'a${String.fromCharCode(c)}b',
        for (final int n in <int>[99, 100, 101, 102, 103]) 'a' * n,
        for (final int n in <int>[99, 100, 101, 102]) '${'a' * n}.json',
        'abc\n',
        '\nabc',
        'aא',
        'א',
        'é.txt',
        'nul',
        'NUL.txt',
        'com1.a.b',
        'lpt9',
        'con.',
        'a..b',
        'end.',
        for (int i = 0; i < 20000; i++)
          String.fromCharCodes(
            List<int>.generate(
              rnd.nextInt(108),
              (_) => rnd.nextInt(4) == 0 ? rnd.nextInt(128) : plain.codeUnitAt(rnd.nextInt(plain.length)),
            ),
          ),
      ];
      for (final String name in names) {
        expect(unsafeNameReason(name), referenceUnsafeNameReason(name), reason: name);
      }
    });

    test('the writer makes the same bytes as before', () {
      final Random rnd = Random(3);
      expect(writeStoredZip(_sample()), referenceWriteStoredZip(_sample()));
      for (int round = 0; round < 200; round++) {
        final List<ZipEntry> entries = List<ZipEntry>.generate(
          1 + rnd.nextInt(30),
          (int i) => ZipEntry('f$i-${rnd.nextInt(1000)}.bin', _random(rnd, rnd.nextInt(3000))),
        );
        expect(writeStoredZip(entries), referenceWriteStoredZip(entries), reason: 'round $round');
      }
    });

    test('every possible change of any single byte of a small zip gets the same answer as before', () {
      final Uint8List good = writeStoredZip(_sample());
      expect(_outcome(readStoredZip, good), _outcome(referenceReadStoredZip, good));
      for (int i = 0; i < good.length; i++) {
        for (int v = 0; v < 256; v++) {
          final Uint8List bad = Uint8List.fromList(good)..[i] = v;
          expect(
            _outcome(readStoredZip, bad),
            _outcome(referenceReadStoredZip, bad),
            reason: 'byte $i set to $v',
          );
        }
      }
    });

    test('random damage gets the same answer as before', () {
      final Random rnd = Random(20261026);
      final Uint8List good = writeStoredZip(_sample());
      for (int round = 0; round < 3000; round++) {
        final Uint8List input = Uint8List.fromList(good);
        final int changes = 1 + rnd.nextInt(6);
        for (int k = 0; k < changes; k++) {
          input[rnd.nextInt(input.length)] = rnd.nextInt(256);
        }
        expect(
          _outcome(readStoredZip, input),
          _outcome(referenceReadStoredZip, input),
          reason: 'round $round',
        );
      }
    });

    test(
      'the real starter pack reads to the same entries as before, and changed bytes get the same reason',
      () {
        final Uint8List pack = _realPack();
        expect(_outcome(readStoredZip, pack), _outcome(referenceReadStoredZip, pack));
        // A sample (the code before needs about 7 ms a byte); the exhaustive proof that every changed byte is
        // refused is in starter_pack_test.dart. The last 22 bytes are the end record.
        for (final int i in <int>[
          for (int i = 0; i < pack.length; i += 4999) i,
          for (int i = pack.length - 22; i < pack.length; i++) i,
        ]) {
          pack[i] ^= 0x01;
          expect(_outcome(readStoredZip, pack), _outcome(referenceReadStoredZip, pack), reason: 'byte $i');
          pack[i] ^= 0x01;
        }
      },
    );
  });
}
