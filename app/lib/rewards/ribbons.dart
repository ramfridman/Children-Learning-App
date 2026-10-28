import 'dart:convert';

/// A parent's promise attached to a trophy ("when you win the gold trophy we go for ice cream"), M8 Q9. The words live in
/// the family's settings and are read only on the family's own phones: shown on that child's trophy and in the parents'
/// alert list. They never go into an event, a push, a log or a prompt.
const int maxPromiseLength = 60;

/// At most this many promises in all (the server holds the same limit).
const int maxPromises = 30;

enum PromiseCheck { ok, empty, tooLong, link, badCharacter }

final RegExp _link = RegExp(
  r'(https?:|www\.|:\/\/|@|\.(com|net|org|il|io|co|app|me)\b)',
  caseSensitive: false,
);

/// Whether [text] may be a promise: 1 to 60 characters, no control characters, no angle brackets, no links or addresses.
/// The server checks the same, so a promise the app accepts is one the family's other phones will receive.
PromiseCheck checkPromise(String text) {
  final String t = text.trim();
  if (t.isEmpty) return PromiseCheck.empty;
  if (t.runes.length > maxPromiseLength) return PromiseCheck.tooLong;
  for (final int c in t.runes) {
    if (c < 0x20 || c == 0x7f || c == 0x3c || c == 0x3e) return PromiseCheck.badCharacter;
  }
  if (_link.hasMatch(t)) return PromiseCheck.link;
  return PromiseCheck.ok;
}

/// Child id, then trophy key, then the words. A damaged value is no promises at all.
typedef Promises = Map<String, Map<String, String>>;

Promises decodeRibbons(String? text) {
  if (text == null || text.isEmpty) return const <String, Map<String, String>>{};
  try {
    final Object? j = jsonDecode(text);
    if (j is! Map<String, Object?>) return const <String, Map<String, String>>{};
    return <String, Map<String, String>>{
      for (final MapEntry<String, Object?> kid in j.entries)
        if (kid.value is Map<String, Object?>)
          kid.key: <String, String>{
            for (final MapEntry<String, Object?> r in (kid.value! as Map<String, Object?>).entries)
              if (r.value is String && checkPromise(r.value! as String) == PromiseCheck.ok)
                r.key: r.value! as String,
          },
    };
  } on FormatException {
    return const <String, Map<String, String>>{};
  }
}

String encodeRibbons(Promises promises) => jsonEncode(<String, Object?>{
  for (final MapEntry<String, Map<String, String>> e in promises.entries)
    if (e.value.isNotEmpty) e.key: e.value,
});

int countPromises(Promises promises) =>
    promises.values.fold<int>(0, (int sum, Map<String, String> m) => sum + m.length);

/// [promises] with the promise for [trophyKey] of [childId] set to [text] (or removed when [text] is empty). Returns null if
/// the words are not allowed or there would be too many promises.
Promises? withPromise(Promises promises, String childId, String trophyKey, String text) {
  final String t = text.trim();
  final Promises out = <String, Map<String, String>>{
    for (final MapEntry<String, Map<String, String>> e in promises.entries)
      e.key: Map<String, String>.of(e.value),
  };
  final Map<String, String> mine = out[childId] ??= <String, String>{};
  if (t.isEmpty) {
    mine.remove(trophyKey);
  } else {
    if (checkPromise(t) != PromiseCheck.ok) return null;
    mine[trophyKey] = t;
  }
  return countPromises(out) > maxPromises ? null : out;
}

/// [promises] without anything for [childId] (a removed child's promises go with the child).
Promises withoutChild(Promises promises, String childId) => <String, Map<String, String>>{
  for (final MapEntry<String, Map<String, String>> e in promises.entries)
    if (e.key != childId) e.key: e.value,
};
