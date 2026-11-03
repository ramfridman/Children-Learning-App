import '../engine/course.dart';

/// A place the bottle on the home island can send the child to (docs/curriculum/todays-adventure-rule.md; for the languages,
/// docs/languages/frame.md section 3.7): one of the lands of the map, or a language the parent turned on. The rule is the same
/// for both; this is only what it needs to know of a place.
abstract interface class AdventureLand {
  /// The place in the fixed order of the map. Every tie in the rule ends on it, so no input order can matter.
  int get order;

  /// A short word that names the land, and nothing else.
  String get key;

  /// The skill domain whose skills the land grows.
  String get domain;
}

/// A language the parent turned on is a land for Today's Adventure. A language that is off is not a land at all. The languages
/// come after the lands that exist, in the fixed order of the doors; the design-director may move them on the map, and
/// [order] is the one place that follows.
class LanguageLand implements AdventureLand {
  const LanguageLand(this.course);

  /// `eng`, `heb` or `rus`.
  final String course;

  @override
  int get order => firstLanguageOrder + Course.languages.indexOf(course);

  @override
  String get key => course;

  @override
  String get domain => Course.languagesDomain;

  /// After the six lands of the trophy hall.
  static const int firstLanguageOrder = 100;

  @override
  bool operator ==(Object other) => other is LanguageLand && other.course == course;

  @override
  int get hashCode => Object.hash('language', course);

  @override
  String toString() => 'LanguageLand($course)';
}
