import '../content/models.dart';

// First meeting is not evidence (docs/milestones/L7.md step L7-3, the owner's answer to Q1 of 2026-11-12). In a visit in which the Meet
// screen of a word played, an item that asks that word is the child's first meeting with it, not a check of what they remember: a right
// tap seconds after hearing the word is short-term memory, and a wrong one is a guess among pictures of words nobody has taught. So such an
// item writes nothing at all: no `incorrect`, no misconception tag, no `correct`. The first evidence is a later lesson's recall. The help
// and the feedback the child sees do not change.

/// The words whose Meet screen has played in one visit, as the clip that says each word.
class FirstMeeting {
  final Set<String> _clips = <String>{};

  /// A Meet screen is on show. A hearing screen of a heritage speaker is not a Meet screen: that child already knows the words and is
  /// scored as always.
  void met(Activity screen) {
    if (screen is! SayItActivity || !screen.meetScreen) return;
    _clips.add(screen.wordClip);
  }

  /// [item] asks a word that was met in this visit (see [askedWords]).
  bool asks(Activity item) {
    if (_clips.isEmpty || item.unscored) return false;
    return askedWords(item).any(_clips.contains);
  }
}

/// The clips of the words an item asks. An item may name its word itself (`asks`: a command such as "show me the arms" has a phrase for a
/// prompt, so that is all it asks). Otherwise they are the clip its prompt ends with (a word to find), the word a say step is to say, and
/// the clip of the right option of a choice (a puppet's bubble: the puppet's line is the prompt, the answer is the word).
Set<String> askedWords(Activity item) {
  if (item.asksClip != null) return <String>{item.asksClip!};
  final Object any = item;
  return <String>{
    ?item.promptLine.target,
    if (item is SayItActivity) item.wordClip,
    if (any is ChoiceActivity)
      ?any.options.where((ChoiceOption o) => o.id == any.correctId).firstOrNull?.clip,
  };
}
