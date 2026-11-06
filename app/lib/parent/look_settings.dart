import 'dart:convert';

// The look a parent chose for a child (B-29): "show a younger or older look", which overrides the presentation the child's age would
// give. It is one letter, A, B or C (the presentation band, 0, 1 or 2), like a language's level, and it travels inside the family's
// rules document under the key `looks`, child id first, so the phone and the tablet agree. The reading setting is not here: it stays
// on the device. Only a child who has a look is in the document, so a family that never sets one syncs exactly what it did before.
// Every value is checked when it is read, on the phone and again on the server (`settings-put`).

/// Where the looks are kept on the device.
const String looksSettingKey = 'looks';

/// The letters of the three bands, in band order (`testvectors/profile-sync.json`).
const List<String> lookLetters = <String>['A', 'B', 'C'];

/// At most this many children have a look (the same six as the language settings; the server holds the same limit).
const int maxLookChildren = 6;

/// The looks of a whole family: child id, then the band 0, 1 or 2. The document is tiny and is replaced as a whole.
class FamilyLooks {
  const FamilyLooks([this._byChild = const <String, int>{}]);

  /// Reads the document. Anything that is not a child's id with one of the three letters is dropped; what the document says about more
  /// than [maxLookChildren] children is cut (the first ones in id order stay).
  factory FamilyLooks.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const FamilyLooks();
    final Map<String, int> out = <String, int>{};
    for (final String child in json.keys.toList()..sort()) {
      final Object? letter = json[child];
      if (!_childId.hasMatch(child) || letter is! String || out.length >= maxLookChildren) continue;
      final int band = lookLetters.indexOf(letter);
      if (band >= 0) out[child] = band;
    }
    return FamilyLooks(out);
  }

  factory FamilyLooks.decode(String? text) {
    if (text == null || text.isEmpty) return const FamilyLooks();
    try {
      return FamilyLooks.fromJson(jsonDecode(text));
    } on FormatException {
      return const FamilyLooks();
    }
  }

  /// The same pattern as a child id everywhere (`child-put`).
  static final RegExp _childId = RegExp(r'^[A-Za-z0-9-]{8,64}$');

  final Map<String, int> _byChild;

  bool get isEmpty => _byChild.isEmpty;

  /// The band (0, 1, 2) the parent chose for this child's look, or null for none (the look follows the age).
  int? bandOf(String childId) => _byChild[childId];

  /// With [band] set for [childId], or the look cleared when [band] is null. Returns null if the id is not a child's, the band is not 0
  /// to 2, or the family would then have a look for more than [maxLookChildren] children.
  FamilyLooks? withBand(String childId, int? band) {
    if (!_childId.hasMatch(childId)) return null;
    if (band != null && (band < 0 || band >= lookLetters.length)) return null;
    final Map<String, int> next = Map<String, int>.of(_byChild);
    if (band == null) {
      next.remove(childId);
    } else {
      if (!next.containsKey(childId) && next.length >= maxLookChildren) return null;
      next[childId] = band;
    }
    return FamilyLooks(next);
  }

  /// Without anything for [childId] (a removed child's look goes with the child).
  FamilyLooks without(String childId) => FamilyLooks(<String, int>{
    for (final MapEntry<String, int> e in _byChild.entries)
      if (e.key != childId) e.key: e.value,
  });

  /// The document, children in id order, each with its letter.
  Map<String, Object?> toJson() => <String, Object?>{
    for (final String id in _byChild.keys.toList()..sort()) id: lookLetters[_byChild[id]!],
  };

  String encode() => jsonEncode(toJson());
}
