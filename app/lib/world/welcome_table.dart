import 'dart:convert';

import '../rewards/award.dart';

/// The daily welcome's lines and which skill goes with which of them (B-42, `docs/milestones/B42.md` sections 4 and 7.2).
/// It is read from `assets/lines/welcome.json`, which `tool/welcome_lines_asset.dart` makes from the editor's lines
/// (`content/lines/core.he.json`) and the curriculum-expert's table (`content/lines/welcome-topics.json`). It holds text
/// the child sees and hears and ids; nothing about a child.
///
/// A skill is looked up in a map built once, never searched for in a list.
class WelcomeTable {
  WelcomeTable._(this._texts, this._topicOfSkill, this._landOfSkill, this._landLine);

  /// Reads the asset's JSON. Throws [FormatException] for anything that is not what the tool writes: a line a topic names
  /// that has no text, a land the app does not have, a skill named twice.
  factory WelcomeTable.parse(String source) {
    final Object? root = jsonDecode(source);
    if (root is! Map<String, Object?> || root['schema'] != 'welcome-lines/v1') {
      throw const FormatException('not a welcome-lines/v1 document');
    }
    final Map<String, String> texts = <String, String>{
      for (final MapEntry<String, Object?> e in (root['lines']! as Map<String, Object?>).entries)
        e.key: e.value! as String,
    };
    String line(Object? id) {
      if (id is String && texts.containsKey(id)) return id;
      throw FormatException('no text for the line $id');
    }

    final Map<String, String> topicOfSkill = <String, String>{};
    final Map<String, TrophyLand> landOfSkill = <String, TrophyLand>{};
    final Map<TrophyLand, String> landLine = <TrophyLand, String>{};
    void place(String skill, TrophyLand land) {
      if (landOfSkill.containsKey(skill)) throw FormatException('$skill is placed twice');
      landOfSkill[skill] = land;
    }

    for (final Object? entry in root['lands']! as List<Object?>) {
      final Map<String, Object?> l = entry! as Map<String, Object?>;
      final TrophyLand land = TrophyLand.values.byName(l['land']! as String);
      if (land.domain != l['domain']) throw FormatException('${land.name} is not the domain ${l['domain']}');
      if (landLine.containsKey(land)) throw FormatException('${land.name} is listed twice');
      landLine[land] = line(l['line']);
      for (final Object? t in l['topics']! as List<Object?>) {
        final Map<String, Object?> topic = t! as Map<String, Object?>;
        final String id = line(topic['line']);
        for (final Object? skill in topic['skills']! as List<Object?>) {
          place(skill! as String, land);
          topicOfSkill[skill as String] = id;
        }
      }
      for (final Object? skill in l['landLine']! as List<Object?>) {
        place(skill! as String, land);
      }
    }
    for (final TrophyLand land in TrophyLand.values) {
      if (!landLine.containsKey(land)) throw FormatException('${land.name} has no land line');
    }
    return WelcomeTable._(texts, topicOfSkill, landOfSkill, landLine);
  }

  final Map<String, String> _texts;
  final Map<String, String> _topicOfSkill;
  final Map<String, TrophyLand> _landOfSkill;
  final Map<TrophyLand, String> _landLine;

  /// Every line's `vo:` id.
  Iterable<String> get lineIds => _texts.keys;

  /// What the bubble shows for the line [voId], with niqqud; throws for an id that is not a line of the welcome.
  String text(String voId) => _texts[voId] ?? (throw ArgumentError.value(voId, 'voId', 'not a welcome line'));

  /// The topic line for [skillId], or null when the skill is not under a topic (it is in a land's `landLine`, or in no row
  /// at all: a skill of a newer pack that nobody has placed yet).
  String? topicOf(String skillId) => _topicOfSkill[skillId];

  /// The land line of [land], always true for every skill of it.
  String landLine(TrophyLand land) => _landLine[land]!;

  /// Whether the table places [skillId] at all (under a topic or by its land line).
  bool places(String skillId) => _landOfSkill.containsKey(skillId);

  /// The land the table places [skillId] in, or null.
  TrophyLand? landOf(String skillId) => _landOfSkill[skillId];

  /// The topic lines in use, each once.
  Set<String> get topicLines => _topicOfSkill.values.toSet();
}
