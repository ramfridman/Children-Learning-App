/// The lesson a land plays next on its path ([orderedIds], first to last): the first lesson that the child has not finished
/// yet; when every lesson has been finished, the one finished fewest times, earliest on the path, so the path goes round
/// and round. [finished] is how many times the child has finished each lesson. Null for an empty path. Pure: the land's own
/// pebble (`nextLessonId`) and Today's Adventure both use it, so they can never disagree.
String? nextOnPath(List<String> orderedIds, Map<String, int> finished) {
  if (orderedIds.isEmpty) return null;
  for (final String id in orderedIds) {
    if ((finished[id] ?? 0) == 0) return id;
  }
  String best = orderedIds.first;
  for (final String id in orderedIds) {
    if ((finished[id] ?? 0) < (finished[best] ?? 0)) best = id;
  }
  return best;
}
