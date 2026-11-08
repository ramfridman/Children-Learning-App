import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/binary_checks.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

// The one rule for what a picture of a pack may contain (binary_checks.dart › svgProblems), checked by the
// builder before signing and by the phone before a pack is installed or loaded. A reference to an element
// of the same file, url(#id), is how a clip path or a gradient is used; flutter_svg resolves it by looking
// the id up in the same document and never fetches anything. Every other url( is refused.

const String _clip =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
    '<defs><clipPath id="c1"><circle cx="50" cy="50" r="40"/></clipPath>'
    '<linearGradient id=\'g-2.b\'><stop offset="0" stop-color="#fff"/></linearGradient></defs>'
    '<g clip-path="url(#c1)"><rect width="100" height="100" fill="url(#g-2.b)"/></g></svg>';

String _with(String attr) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
    '<defs><clipPath id="c1"><circle cx="50" cy="50" r="40"/></clipPath></defs>'
    '<rect width="100" height="100" $attr/></svg>';

void main() {
  group('allowed', () {
    test('url(#id) of a clip path and of a gradient defined in the same file', () {
      expect(svgProblems(_clip), isEmpty);
    });

    test('a picture with no url( at all, and the five named character references', () {
      expect(
        svgProblems('<svg viewBox="0 0 1 1"><desc>a &amp; b &lt; c &gt; d &quot;&apos;</desc></svg>'),
        isEmpty,
      );
    });
  });

  group('refused', () {
    const Map<String, String> external = <String, String>{
      'http': 'fill="url(http://example.com/x.svg#a)"',
      'https': 'fill="url(https://example.com/a)"',
      'protocol-relative': 'fill="url(//example.com/a)"',
      'data:': 'fill="url(data:image/svg+xml;base64,PHN2Zy8+)"',
      'file': 'clip-path="url(file:///etc/passwd#a)"',
      'relative path': 'clip-path="url(other.svg#c1)"',
      'quoted': "clip-path=\"url('#c1')\"",
      'spaced': 'clip-path="url( #c1 )"',
      'space before (': 'clip-path="url (#c1)"',
      'upper case': 'clip-path="URL(#c1)"',
      'empty': 'clip-path="url()"',
      'empty fragment': 'clip-path="url(#)"',
      'inside a style attribute': 'style="fill:url(https://example.com/a)"',
      'javascript': 'fill="url(javascript:alert(1))"',
    };
    for (final MapEntry<String, String> e in external.entries) {
      test('url( that is not a fragment of this file: ${e.key}', () {
        expect(svgProblems(_with(e.value)), isNotEmpty, reason: e.value);
      });
    }

    test('url(#id) whose id is not defined in the file', () {
      expect(svgProblems(_with('clip-path="url(#nowhere)"')), <String>[
        'refers to url(#nowhere), which this file does not define',
      ]);
    });

    test('an id that only looks defined (another attribute ending in id) does not count', () {
      expect(svgProblems(_with('data-id="x" clip-path="url(#x)"')), isNotEmpty);
    });

    test('the address is never repeated in the problem (problems can reach a log)', () {
      final List<String> p = svgProblems(_with('fill="url(https://example.com/secret)"'));
      expect(p.join(), isNot(contains('example.com')));
    });

    test('a numeric character reference (it could spell u&#114;l( past the check)', () {
      expect(svgProblems(_with('clip-path="u&#114;l(http://x)"')), isNotEmpty);
      expect(svgProblems(_with('fill="&#x23;fff"')), isNotEmpty);
    });

    test('a DTD or an entity declaration', () {
      expect(svgProblems('<!DOCTYPE svg [<!ENTITY a "b">]><svg viewBox="0 0 1 1"/>'), isNotEmpty);
    });

    for (final String bad in <String>[
      '<script>x</script>',
      '<image href="http://x/y.png"/>',
      '<image xlink:href="data:image/png;base64,AAAA"/>',
      '<use href="#c1"/>',
      '<a href="https://example.com"><rect/></a>',
      '<style>rect{fill:red}</style>',
      '<foreignObject><p>x</p></foreignObject>',
      '<rect onload="x()"/>',
    ]) {
      test('markup that could run or fetch something: $bad', () {
        expect(svgProblems(_with('').replaceFirst('</svg>', '$bad</svg>')), isNotEmpty, reason: bad);
      });
    }
  });

  group('the phone enforces it on every SVG of a pack, not only on characters', () {
    late PackKey key;
    late Uint8List pack;

    setUpAll(() async {
      key = await newTestKey();
      pack = (await buildSamplePack(key)).bytes;
    });

    Future<Uint8List> withSvg(String text) => forge(
      key,
      pack,
      files: (Map<String, Uint8List> f) => f['jar.svg'] = Uint8List.fromList(utf8.encode(text)),
    );

    test('a signed pack whose picture uses url(#id) of its own clip path installs', () async {
      final VerifiedPack v = await verifyWith(await withSvg(_clip), key);
      expect(utf8.decode(v.files['jar.svg']!), _clip);
    });

    test('a signed pack whose picture points url( outside the file is refused before use', () async {
      for (final String attr in <String>[
        'fill="url(https://example.com/a)"',
        'clip-path="url(other.svg#c1)"',
        'clip-path="url(#nowhere)"',
      ]) {
        await expectLater(
          verifyWith(await withSvg(_with(attr)), key),
          throwsA(
            isA<PackRejected>()
                .having((PackRejected e) => e.stage, 'stage', 'content')
                .having((PackRejected e) => e.problems.join('\n'), 'problems', contains('jar.svg')),
          ),
          reason: attr,
        );
      }
    });

    test(
      'a signed pack whose picture has a script is refused (it used to be checked only for characters)',
      () async {
        await expectLater(
          verifyWith(await withSvg(_with('').replaceFirst('</svg>', '<script>x</script></svg>')), key),
          throwsA(isA<PackRejected>().having((PackRejected e) => e.stage, 'stage', 'content')),
        );
      },
    );
  });

  test('every bundled pack (the starter and the language packs) follows the rule in every picture', () {
    final List<File> packs = Directory('assets/packs')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.nnpack'))
        .toList();
    expect(packs, isNotEmpty);
    for (final File p in packs) {
      int svgs = 0;
      for (final ZipEntry e in readStoredZip(p.readAsBytesSync())) {
        if (!e.name.endsWith('.svg')) continue;
        svgs++;
        expect(svgProblems(utf8.decode(e.data)), isEmpty, reason: '${p.path} › ${e.name}');
      }
      expect(svgs, greaterThan(0), reason: p.path);
    }
  });
}
