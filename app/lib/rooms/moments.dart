/// Who is talking in a moment of a lesson (docs/design/m11-rooms.md section 2.1): the host of the room teaches, the child's own companion
/// asks, helps and answers.
enum Speaker { host, companion }

/// The moments of a lesson that have a speaker of their own. Stage 1 has the greeting, the child's turns and the cheer; Stage 2 adds the Show and
/// the lead-in of a Together item, which are the host's too, by adding them here and to [speaker]: nothing else about "who speaks" is decided
/// anywhere else.
enum Moment {
  /// The first screen of a lesson, before its first item: the host greets, the companion listens.
  greeting,

  /// Every item the child answers, with its hints and its feedback: the companion's.
  turn,

  /// The end of the lesson: the host cheers beside the companion in the celebration.
  cheer;

  Speaker get speaker => switch (this) {
    greeting || cheer => Speaker.host,
    turn => Speaker.companion,
  };
}
