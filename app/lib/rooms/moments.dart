import '../strings/niqqud.dart';

/// Whether the companion's [praise] at the end of a lesson only says again what the host's [cheer] already said (the words of the praise,
/// without niqqud and punctuation, are inside the cheer). The child then hears and sees the host's cheer once, and not the same line twice.
bool cheerRepeatsPraise(String praise, String cheer) {
  final String said = _words(praise);
  return said.isNotEmpty && _words(cheer).contains(said);
}

String _words(String text) =>
    withoutNiqqud(text)
        .replaceAll(RegExp('[^\\u05D0-\\u05EAa-zA-Z0-9 ]'), ' ')
        .split(' ')
        .where((String w) => w.isNotEmpty)
        .join(' ');

/// Who is talking in a moment of a lesson (docs/design/m11-rooms.md section 2.1): the host of the room teaches, the child's own companion
/// asks, helps and answers.
enum Speaker { host, companion }

/// The moments of a lesson that have a speaker of their own: the greeting, the Meet screens of a language course (the course host introduces
/// the new words), the child's turns and the cheer. Stage 2 adds the Show and the lead-in of a Together item, which are the host's too, by adding
/// them here and to [speaker]: nothing else about "who speaks" is decided anywhere else.
enum Moment {
  /// The first screen of a lesson, before its first item: the host greets, the companion listens.
  greeting,

  /// A Meet screen of a language course in its room (docs/design/m11-rooms.md section 6): the course host teaches the word, the companion
  /// listens behind it. The companion's own lines inside a Meet (the microphone's feedback) are the session's to mark, not another moment.
  meet,

  /// Every item the child answers, with its hints and its feedback: the companion's.
  turn,

  /// The end of the lesson: the host cheers beside the companion in the celebration.
  cheer;

  Speaker get speaker => switch (this) {
    greeting || meet || cheer => Speaker.host,
    turn => Speaker.companion,
  };
}
