import '../world/world_state.dart' show WorldObject;

/// The `vo:` ids a document (an activity, a lesson) asks for, in the order they appear, each once.
List<String> voiceLinesOf(Iterable<Map<String, Object?>> documents) {
  final Set<String> found = <String>{};
  void walk(Object? node) {
    if (node is String) {
      if (node.startsWith('vo:')) found.add(node);
    } else if (node is Map<String, Object?>) {
      node.values.forEach(walk);
    } else if (node is List<Object?>) {
      node.forEach(walk);
    }
  }

  documents.forEach(walk);
  return found.toList();
}

final RegExp _skillIdShape = RegExp(r'^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$');

/// The `vo:` id of the recorded map-card line (`childLine`) of the skill [skillId]: `COL-A-01` is `vo:core.skill.col_a_01`
/// (lower case, hyphens to underscores; the lines are in the core pack, which is always in memory). Null for an id that
/// cannot make a valid voice id, so that nothing odd is ever asked of the bank. This is the only place the mapping is written.
String? skillLineVoiceId(String skillId) {
  if (!_skillIdShape.hasMatch(skillId)) return null;
  return 'vo:core.skill.${skillId.toLowerCase().replaceAll('-', '_')}';
}

/// The recorded ids of the map-card lines of [objects] (those that show a `childLine`), each once, for [VoiceDirector.prefetch].
List<String> cardLineVoiceIds(Iterable<WorldObject> objects) => <String>[
  for (final WorldObject o in objects)
    if (o.line != null) ?skillLineVoiceId(o.skillId),
];
