import 'capabilities.dart' show compareSemver;

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
