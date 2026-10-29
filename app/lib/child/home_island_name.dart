// The words on the child's home island: the map sign, the home screen's title and the screen-reader text, from the
// name the parent typed (B-26; the rules are the hebrew-text-editor's, docs/agents/b26-hebrew.md section 1).
//
// The name is shown as typed and only on this device; nothing here sends, stores or logs it. Lengths are counted in
// grapheme clusters, so a letter with its nikud is one and nikud never decides whether a name is shortened.

// Only `String.characters` (grapheme clusters): the `characters` package reaches the app through Flutter, and
// importing it directly would make it a new direct dependency.
import 'package:flutter/widgets.dart' show StringCharacters;

import '../strings/he.dart';

/// Marks the end of a shortened name.
const String ellipsis = '\u2026';

/// The longest name the home screen's title shows whole (the guard for the parent form's 40 characters).
const int titleMaxClusters = 24;

// The name sits in a first-strong isolate, so a Latin name and its ellipsis keep their order in the Hebrew line.
const String _isolateStart = '\u2068';
const String _isolateEnd = '\u2069';
const String _noBreakSpace = '\u00A0';
const String _childSlot = '{child}';

// Format characters: direction marks and isolates, zero-width characters, the byte-order mark, the soft hyphen.
final RegExp _format = RegExp(r'\p{Cf}', unicode: true);
// Any white space, also a tab, a new line or a no-break space.
final RegExp _space = RegExp(r'\s');
final RegExp _control = RegExp(r'\p{Cc}', unicode: true);
final RegExp _spaceRun = RegExp(' {2,}');
final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// What stands between the parts of a name: a space, a hyphen or a maqaf.
const Set<String> _separators = <String>{' ', '-', '\u05BE'};

/// A geresh as parents type it: an apostrophe, the Hebrew geresh, or the curly apostrophe a phone keyboard puts in.
const Set<String> _gereshes = <String>{'\'', '\u05F3', '\u2019'};

/// The title's frame words are joined by a no-break space, so the title only wraps before the name.
final Str _titleWithName = Str(_keepFrameTogether(He.homeIsland.text), nikud: true);

/// What the home island is called for one child.
class HomeIslandName {
  const HomeIslandName._({
    required this.name,
    required this.sign,
    required this.title,
    required this.semantics,
  });

  /// The name as typed after the clean-up (trimmed, white space collapsed, invisible characters removed); empty when
  /// there is no usable name.
  final String name;

  /// The map sign with the whole name. The sign widget may shorten it with [signShortened] to fit its box.
  final String sign;

  /// The home screen's title: the whole name, unless it is longer than [titleMaxClusters].
  final String title;

  /// The screen reader's text: unpointed words and the whole plain name.
  final String semantics;

  /// False when the fallback ("my island") is shown.
  bool get isNamed => name.isNotEmpty;

  /// The sign with the name shortened to at most [maxClusters] grapheme clusters by [shortenName]. The fallback sign
  /// has no name and is returned as it is.
  String signShortened(int maxClusters) =>
      isNamed ? _withName(He.homeIsland, shortenName(name, maxClusters)) : sign;
}

/// The island's words for the name [typed] by the parent (null or blank: the fallback).
HomeIslandName homeIslandName(String? typed) {
  final String name = _clean(typed ?? '');
  if (!_letter.hasMatch(name)) {
    return HomeIslandName._(
      name: '',
      sign: He.homeIslandMine.text,
      title: He.homeIslandMine.text.replaceAll(' ', _noBreakSpace),
      semantics: He.homeIslandMineSemantics.text,
    );
  }
  return HomeIslandName._(
    name: name,
    sign: _withName(He.homeIsland, name),
    title: _withName(_titleWithName, shortenName(name, titleMaxClusters)),
    semantics: He.homeIslandSemantics.fill(<String, String>{'child': name}),
  );
}

/// [cleanName] cut to at most [maxClusters] grapheme clusters, the closing [ellipsis] included; a name that fits is
/// returned unchanged. The hebrew-text-editor's rule:
/// 1. whole parts first: the longest run of whole parts from the start (split at a space, a hyphen or a maqaf) that
///    fits and holds at least two letters;
/// 2. otherwise letters, never leaving a letter without its geresh and never ending on a space or a hyphen.
/// The caller picks [maxClusters] (the sign widget measures its box); it is at least 3.
String shortenName(String cleanName, int maxClusters) {
  if (maxClusters < 3) throw RangeError.range(maxClusters, 3, null, 'maxClusters');
  final List<String> clusters = cleanName.characters.toList();
  if (clusters.length <= maxClusters) return cleanName;
  final int room = maxClusters - 1; // one cluster is the ellipsis
  return '${_wholeParts(clusters, room) ?? _firstLetters(clusters, room)}$ellipsis';
}

/// The longest start of [clusters] that ends where a part ends, is at most [room] long and holds two letters.
String? _wholeParts(List<String> clusters, int room) {
  int end = 0;
  int letters = 0;
  for (int i = 0; i < room; i++) {
    if (_letter.hasMatch(clusters[i])) letters++;
    final bool partEnds = !_separators.contains(clusters[i]) && _separators.contains(clusters[i + 1]);
    if (partEnds && letters >= 2) end = i + 1;
  }
  return end == 0 ? null : clusters.sublist(0, end).join();
}

/// The first [room] clusters, one fewer if the next one is a geresh, without a trailing separator.
String _firstLetters(List<String> clusters, int room) {
  int end = room;
  if (_gereshes.contains(clusters[end])) end--;
  while (end > 1 && _separators.contains(clusters[end - 1])) {
    end--;
  }
  return clusters.sublist(0, end).join();
}

String _clean(String typed) => typed
    .replaceAll(_format, '')
    .replaceAll(_space, ' ')
    .replaceAll(_control, '')
    .replaceAll(_spaceRun, ' ')
    .trim();

String _withName(Str pattern, String name) =>
    pattern.fill(<String, String>{'child': '$_isolateStart$name$_isolateEnd'});

/// [pattern] with the spaces between its words before the name made no-break.
String _keepFrameTogether(String pattern) {
  final String frame = pattern.substring(0, pattern.indexOf(_childSlot)).trimRight();
  return frame.replaceAll(' ', _noBreakSpace) + pattern.substring(frame.length);
}
