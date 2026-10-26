import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart' show crc32;

import '../../tool/pack_builder_lib.dart';

/// A valid PNG of [w] by [h] pixels, one colour (made here so the tests need no image files).
Uint8List makePng(int w, int h, {int shade = 200}) {
  final BytesBuilder out = BytesBuilder();
  void chunk(String type, List<int> data) {
    final Uint8List body = Uint8List.fromList(<int>[...type.codeUnits, ...data]);
    final ByteData len = ByteData(4)..setUint32(0, data.length);
    out
      ..add(len.buffer.asUint8List())
      ..add(body);
    final ByteData crc = ByteData(4)..setUint32(0, crc32(body));
    out.add(crc.buffer.asUint8List());
  }

  out.add(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final ByteData ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8)
    ..setUint8(9, 6); // 8 bits, RGBA
  chunk('IHDR', ihdr.buffer.asUint8List());
  final Uint8List raw = Uint8List(h * (1 + 4 * w));
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      raw[y * (1 + 4 * w) + 1 + 4 * x] = shade;
      raw[y * (1 + 4 * w) + 1 + 4 * x + 3] = 255;
    }
  }
  chunk('IDAT', ZLibEncoder().convert(raw));
  chunk('IEND', const <int>[]);
  return out.toBytes();
}

const List<String> poseFiles = <String>[
  'idle',
  'talk_closed',
  'talk_open',
  'celebrate',
  'think',
  'listen',
  'encourage',
];

/// A character folder in the family-pack format with small test pictures.
Directory writeCharacterFolder(
  Directory root,
  String id, {
  int size = 64,
  bool personal = true,
  String nameHe = '{name} הַמְּזַנֵּק',
  List<String> roles = const <String>[
    'guide_tutor',
    'activity_helper',
    'celebration_cameo',
    'map_companion',
    'sticker',
  ],
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  final Directory dir = Directory('${root.path}${Platform.pathSeparator}$id')..createSync(recursive: true);
  for (final String p in poseFiles) {
    File('${dir.path}${Platform.pathSeparator}$p.png')
        .writeAsBytesSync(makePng(size, size, shade: 100 + poseFiles.indexOf(p) * 20));
  }
  final Map<String, Object?> pack = <String, Object?>{
    'schema': 'character-lite/v1',
    'id': id,
    'name': <String, Object?>{'he': nameHe, 'template': nameHe, 'grammaticalGender': 'masculine'},
    'roles': roles,
    'images': <String, Object?>{for (final String p in poseFiles) p: '$p.png'},
    'canvas': <String, Object?>{
      'size': <int>[size, size],
    },
    'mouth': <double>[0.45, 0.5],
    'palette': <String, Object?>{'dominant': '#3A7FA0'},
    'availability': <String, Object?>{
      'distribution': personal ? 'personal' : 'bundled',
      'personalUseOnly': personal,
    },
    ...extra,
  };
  File('${dir.path}${Platform.pathSeparator}pack.json').writeAsStringSync(jsonEncode(pack));
  return dir;
}

Future<Character> characterFrom(BuiltPack built, PackKey key) async =>
    Character.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
