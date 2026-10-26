import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Offset, Size;

import '../content/pack_verify.dart';

/// What a screen asks for: a role, never a particular character.
enum CharacterRole {
  guideTutor('guide_tutor'),
  mapCompanion('map_companion'),
  celebrationCameo('celebration_cameo'),
  activityHelper('activity_helper'),
  sticker('sticker');

  const CharacterRole(this.wire);

  final String wire;

  static CharacterRole? parse(String s) {
    for (final CharacterRole r in CharacterRole.values) {
      if (r.wire == s) return r;
    }
    return null;
  }
}

/// What a character is doing. `talk` shows the mouth open or closed by the lip-sync.
enum CharacterState { idle, talk, listen, think, encourage, celebrate, surprised, sleepy, wave }

/// One picture of a character: an SVG drawing or a PNG.
class CharacterImage {
  const CharacterImage.svg(String text) : svg = text, png = null;

  const CharacterImage.png(Uint8List bytes) : png = bytes, svg = null;

  final String? svg;
  final Uint8List? png;
}

/// A character that is installed and may be shown: its name, roles and pictures.
class Character {
  const Character({
    required this.id,
    required this.packId,
    required this.nameHe,
    required this.gender,
    required this.roles,
    required this.personalUseOnly,
    required this.mouth,
    required this.canvas,
    required this.images,
  });

  /// Reads the character of a verified character pack (`char-<id>`).
  factory Character.fromPack(VerifiedPack pack) {
    final MapEntry<String, Object?> docEntry = pack.docs.entries.firstWhere(
      (MapEntry<String, Object?> d) => d.key.startsWith('character.'),
    );
    final Map<String, Object?> doc = docEntry.value! as Map<String, Object?>;
    final Map<String, String> fileOf = <String, String>{
      for (final Object? a in pack.manifest['assets']! as List<Object?>)
        (a! as Map<String, Object?>)['id']! as String: (a as Map<String, Object?>)['file']! as String,
    };
    final Map<String, CharacterImage> images = <String, CharacterImage>{};
    for (final MapEntry<String, Object?> e in (doc['images']! as Map<String, Object?>).entries) {
      final String file = fileOf[(e.value! as String).substring('asset:'.length)]!;
      final Uint8List bytes = pack.files[file]!;
      images[e.key] = file.endsWith('.svg')
          ? CharacterImage.svg(utf8.decode(bytes))
          : CharacterImage.png(bytes);
    }
    final Map<String, Object?> name = doc['name']! as Map<String, Object?>;
    final List<Object?> mouth = doc['mouth']! as List<Object?>;
    final Map<String, Object?> canvas = doc['canvas']! as Map<String, Object?>;
    return Character(
      id: doc['id']! as String,
      packId: pack.id,
      nameHe: name['he']! as String,
      gender: name['gender']! as String,
      roles: <CharacterRole>{
        for (final Object? r in doc['roles']! as List<Object?>) ?CharacterRole.parse(r! as String),
      },
      personalUseOnly: doc['personalUseOnly']! as bool,
      mouth: Offset((mouth[0]! as num).toDouble(), (mouth[1]! as num).toDouble()),
      canvas: Size((canvas['width']! as int).toDouble(), (canvas['height']! as int).toDouble()),
      images: images,
    );
  }

  final String id;
  final String packId;

  /// The Hebrew name with niqqud; a family character's may hold `{name}` for the child's name.
  final String nameHe;

  /// `m` or `f`: how the character speaks about itself.
  final String gender;
  final Set<CharacterRole> roles;
  final bool personalUseOnly;

  /// Where the mouth is, as a share of the picture's width and height.
  final Offset mouth;
  final Size canvas;
  final Map<String, CharacterImage> images;

  bool allows(CharacterRole r) => roles.contains(r);

  /// The name to show, with the child's first name filled in where the character's name asks for it.
  String displayName(String childName) => nameHe.replaceAll('{name}', childName).trim();

  /// The picture for a state. A character without an optional picture borrows a close one.
  CharacterImage imageFor(CharacterState s, {bool mouthOpen = false}) {
    CharacterImage pick(List<String> keys) {
      for (final String k in keys) {
        final CharacterImage? i = images[k];
        if (i != null) return i;
      }
      return images['idle']!;
    }

    return switch (s) {
      CharacterState.idle => pick(<String>['idle']),
      CharacterState.talk => pick(mouthOpen ? <String>['talk_open'] : <String>['talk_closed']),
      CharacterState.listen => pick(<String>['listen']),
      CharacterState.think => pick(<String>['think']),
      CharacterState.encourage => pick(<String>['encourage']),
      CharacterState.celebrate => pick(<String>['celebrate']),
      CharacterState.surprised => pick(<String>['surprised', 'celebrate']),
      CharacterState.sleepy => pick(<String>['sleepy', 'idle']),
      CharacterState.wave => pick(<String>['wave', 'celebrate']),
    };
  }
}
