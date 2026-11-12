import '../content/models.dart';

// First meeting is not evidence (docs/milestones/L7.md step L7-3, the owner's answer to Q1 of 2026-11-12). In a visit in which the Meet
// screen of a word played, an item that asks that word is the child's first meeting with it, not a check of what they remember: a right
// tap seconds after hearing the word is short-term memory, and a wrong one is a guess among pictures of words nobody has taught. So such an
// item writes nothing at all: no `incorrect`, no misconception tag, no `correct`. The first evidence is a later lesson's recall. The help
// and the feedback the child sees do not change.

/// The words whose Meet screen has played in one visit, as the clip that says each word and the picture that shows it.
class FirstMeeting {
  final Set<String> _clips = <String>{};
  final Set<String> _pictures = <String>{};

  /// A Meet screen is on show. A hearing screen of a heritage speaker is not a Meet screen: that child already knows the words and is
  /// scored as always.
  void met(Activity screen) {
    if (screen is! SayItActivity || !screen.teach || screen.hear) return;
    _clips.add(screen.wordClip);
    _pictures.add(screen.picture);
  }

  /// [item] asks a word that was met in this visit. Its target is told by the clip its prompt ends with (a word to find, a word to say) or by
  /// the correct picture of a choice. A command such as "show me the arms" names its target by a spot on one scene: there only the author's
  /// label of the spot is left (`arms`), which is the end of the name of the Meet screen's picture (`body_arms`). Until an item names its
  /// word itself (L7-4), that is how those are told.
  bool asks(Activity item) {
    if (_clips.isEmpty || item.unscored) return false;
    final String? spoken = item.promptLine.target;
    if (spoken != null && _clips.contains(spoken)) return true;
    if (item is SayItActivity && _clips.contains(item.wordClip)) return true;
    final Object any = item;
    if (any is! ChoiceActivity) return false;
    final ChoiceOption? right = any.options.where((ChoiceOption o) => o.id == any.correctId).firstOrNull;
    if (right == null) return false;
    if (right.clip != null && _clips.contains(right.clip)) return true;
    if (right.sprite != null) return _pictures.contains(right.sprite);
    final String? label = right.label;
    return label != null && _pictures.any((String p) => p.endsWith('_$label'));
  }
}
