import 'dart:convert';
import 'dart:typed_data';

import 'schema.dart';

/// Checks on the pictures of character packs, which `validatePack` cannot make because it never sees bytes.
/// Runs after every file has been proven genuine, in the app and in the builder.

const int maxCharacterBytes = 8 * 1024 * 1024;

/// Things a picture of a character must not contain, whatever it claims to be.
const List<String> _unsafeSvg = <String>[
  '<script',
  'href',
  'data:',
  '<image',
  '<foreignobject',
  'onload',
  'onclick',
  '<style',
  'url(',
  '<use',
];

final RegExp _viewBox = RegExp(r'viewBox="\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)\s*"');

/// The width and height of a PNG from its header, or null if the bytes are not a PNG.
(int, int)? pngSize(Uint8List b) {
  if (b.length < 33) return null;
  const List<int> sig = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (int i = 0; i < 8; i++) {
    if (b[i] != sig[i]) return null;
  }
  // The first chunk must be IHDR.
  if (String.fromCharCodes(b, 12, 16) != 'IHDR') return null;
  final ByteData v = ByteData.sublistView(b);
  return (v.getUint32(16), v.getUint32(20));
}

/// Problems with the pictures of every character in a verified pack.
List<Problem> checkCharacterFiles(
  Map<String, Object?> manifest,
  Map<String, Object?> docs,
  Map<String, Uint8List> files,
) {
  final List<Problem> out = <Problem>[];
  final Map<String, String> assetFile = <String, String>{
    for (final Object? a in manifest['assets']! as List<Object?>)
      (a! as Map<String, Object?>)['id']! as String: (a as Map<String, Object?>)['file']! as String,
  };
  for (final MapEntry<String, Object?> d in docs.entries) {
    if (!d.key.startsWith('character.')) continue;
    final Map<String, Object?> doc = d.value! as Map<String, Object?>;
    final Map<String, Object?> canvas = doc['canvas']! as Map<String, Object?>;
    final int w = canvas['width']! as int;
    final int h = canvas['height']! as int;
    int total = 0;
    for (final MapEntry<String, Object?> img in (doc['images']! as Map<String, Object?>).entries) {
      final String where = 'images.${img.key}';
      final String? name = assetFile[(img.value! as String).substring('asset:'.length)];
      final Uint8List? bytes = name == null ? null : files[name];
      if (bytes == null) {
        out.add(Problem('${d.key} › $where', 'the picture is missing'));
        continue;
      }
      total += bytes.length;
      if (name!.endsWith('.png')) {
        final (int, int)? size = pngSize(bytes);
        if (size == null) {
          out.add(Problem('${d.key} › $where', '$name is not a PNG'));
        } else if (size.$1 != w || size.$2 != h) {
          out.add(Problem('${d.key} › $where', '$name is ${size.$1}×${size.$2}, the canvas is $w×$h'));
        }
      } else if (name.endsWith('.svg')) {
        final String text;
        try {
          text = utf8.decode(bytes);
        } on FormatException {
          out.add(Problem('${d.key} › $where', '$name is not valid UTF-8'));
          continue;
        }
        final String lower = text.toLowerCase();
        for (final String bad in _unsafeSvg) {
          if (lower.contains(bad)) out.add(Problem('${d.key} › $where', '$name contains "$bad"'));
        }
        final RegExpMatch? m = _viewBox.firstMatch(text);
        if (m == null) {
          out.add(Problem('${d.key} › $where', '$name has no viewBox starting at 0 0'));
        } else if (double.parse(m.group(1)!).round() != w || double.parse(m.group(2)!).round() != h) {
          out.add(
            Problem(
              '${d.key} › $where',
              '$name has the viewBox ${m.group(1)}×${m.group(2)}, the canvas is $w×$h',
            ),
          );
        }
      } else {
        out.add(Problem('${d.key} › $where', '$name is neither a PNG nor an SVG'));
      }
    }
    if (total > maxCharacterBytes) {
      out.add(Problem(d.key, 'the pictures take $total bytes; the limit is $maxCharacterBytes'));
    }
  }
  return out;
}
