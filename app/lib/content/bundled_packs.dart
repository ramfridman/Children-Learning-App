import '../voice/voice_bank.dart' show voicePackId;
import 'capabilities.dart' show compareSemver;

/// The version of the starter pack that ships in the app: the one line to change at a pack bump (with `version` in
/// `content/starter/pack.json`, which a test compares it to). The file is `assets/packs/starter-<version>.nnpack`.
const String bundledStarterVersion = '0.11.0';

/// The asset path of the bundled starter pack.
const String bundledStarterAsset = 'assets/packs/starter-$bundledStarterVersion.nnpack';

/// A language pack that ships inside the app: `assets/packs/lang-<course>-<version>.nnpack`, signed by the owner with the same key and
/// the same tool as the starter pack (`pack_builder build-language`). The app does not trust the file name: the pack is installed
/// through the verifying installer like any other, and its own manifest says what it is. The name only says which course it is for
/// and which version, so the app knows without opening it whether the copy on the phone is already this one or newer.
class BundledLanguagePack {
  const BundledLanguagePack({required this.course, required this.version, required this.asset});

  final String course;
  final String version;

  /// The asset path (`assets/packs/lang-eng-0.1.0.nnpack`).
  final String asset;

  static final RegExp _name = RegExp(
    r'^assets/packs/lang-(eng|heb|rus)-(\d{1,3}\.\d{1,3}\.\d{1,3})\.nnpack$',
  );

  /// The newest bundled pack of each course among [assets] (every path of the asset manifest; whatever is not a language pack is
  /// left out). A map by course: there is one pack per course.
  static Map<String, BundledLanguagePack> newestOf(Iterable<String> assets) {
    final Map<String, BundledLanguagePack> out = <String, BundledLanguagePack>{};
    for (final String asset in assets) {
      final RegExpMatch? m = _name.firstMatch(asset);
      if (m == null) continue;
      final BundledLanguagePack found = BundledLanguagePack(
        course: m.group(1)!,
        version: m.group(2)!,
        asset: asset,
      );
      final BundledLanguagePack? have = out[found.course];
      if (have == null || compareSemver(found.version, have.version) > 0) out[found.course] = found;
    }
    return out;
  }
}

/// The characters whose voice ships inside the app: only those whose character pack says `distribution: bundled`. Today that is
/// Nitzi alone. Every other character (Hero-son, the seven friends) is personal and its voice is never bundled (CLAUDE.md); the
/// list is a constant, not read from a file name, so a file dropped into the assets can never add a character to it.
const Set<String> bundledVoiceCharacters = <String>{'nitzi'};

/// A voice pack that ships inside the app: `assets/characters/voice-<id>-<version>.nnpack` for the first part of the voice of a
/// bundled character and `voice-<id>-<N>-<version>.nnpack` for the part N from 2 to 9 ([voicePackId]), and
/// `assets/packs/voice-lang-<course>-<version>.nnpack` for the voice of a language course (character id `lang-<course>`, one
/// part). The files are copied in at
/// build time (`tools/copy-release-voices.ps1`) and are not in the repository. The app does not trust the name: each file goes
/// through the verifying installer, and its own manifest says what it is. The name says which pack and which version, so the app
/// knows without opening it whether the copy on the phone is this one or newer.
class BundledVoicePack {
  const BundledVoicePack({
    required this.characterId,
    required this.part,
    required this.version,
    required this.asset,
  });

  /// `nitzi`, or `lang-eng`, `lang-heb`, `lang-rus` for the voice of a course.
  final String characterId;

  /// 1 for `voice-<id>`, 2 to 9 for `voice-<id>-N`.
  final int part;
  final String version;

  /// The asset path (`assets/characters/voice-nitzi-2-2.0.0.nnpack`).
  final String asset;

  /// The id of the installed pack (`voice-nitzi`, `voice-nitzi-2`).
  String get packId => voicePackId(characterId, part);

  static final RegExp _name = RegExp(
    '^assets/characters/voice-(${bundledVoiceCharacters.join('|')})'
    r'(?:-([2-9]))?-(\d{1,3}\.\d{1,3}\.\d{1,3})\.nnpack$',
  );

  static final RegExp _lang = RegExp(
    r'^assets/packs/voice-lang-(eng|heb|rus)-(\d{1,3}\.\d{1,3}\.\d{1,3})\.nnpack$',
  );

  /// The newest bundled file of each voice pack among [assets] (every path of the asset manifest; whatever is not a voice pack of
  /// a bundled character is left out), by character and part.
  static List<BundledVoicePack> newestOf(Iterable<String> assets) {
    final Map<String, BundledVoicePack> out = <String, BundledVoicePack>{};
    for (final String asset in assets) {
      final RegExpMatch? m = _name.firstMatch(asset);
      final RegExpMatch? l = m == null ? _lang.firstMatch(asset) : null;
      if (m == null && l == null) continue;
      final BundledVoicePack found = m != null
          ? BundledVoicePack(
              characterId: m.group(1)!,
              part: m.group(2) == null ? 1 : int.parse(m.group(2)!),
              version: m.group(3)!,
              asset: asset,
            )
          : BundledVoicePack(characterId: 'lang-${l!.group(1)}', part: 1, version: l.group(2)!, asset: asset);
      final BundledVoicePack? have = out[found.packId];
      if (have == null || compareSemver(found.version, have.version) > 0) out[found.packId] = found;
    }
    return out.values.toList()
      ..sort((BundledVoicePack a, BundledVoicePack b) => a.packId.compareTo(b.packId));
  }
}
