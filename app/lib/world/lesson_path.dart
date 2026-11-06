/// The lesson a land plays next on its path ([orderedIds], first to last): the first lesson that the child has not finished
/// yet; when every lesson has been finished, the one finished fewest times, earliest on the path, so the path goes round
/// and round. [finished] is how many times the child has finished each lesson. A lesson in [locked] is not offered (the path
/// gate, `path_gate.dart`): it is skipped, and comes back when it is not locked any more. Null for an empty path, or when every
/// lesson is locked. Pure: the land's own pebble (`nextLessonId`) and Today's Adventure both use it, so they can never disagree.
String? nextOnPath(
  List<String> orderedIds,
  Map<String, int> finished, {
  Set<String> locked = const <String>{},
}) {
  final List<String> open = <String>[
    for (final String id in orderedIds)
      if (!locked.contains(id)) id,
  ];
  if (open.isEmpty) return null;
  for (final String id in open) {
    if ((finished[id] ?? 0) == 0) return id;
  }
  String best = open.first;
  for (final String id in open) {
    if ((finished[id] ?? 0) < (finished[best] ?? 0)) best = id;
  }
  return best;
}
