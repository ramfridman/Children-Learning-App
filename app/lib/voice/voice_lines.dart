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
