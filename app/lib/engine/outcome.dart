import 'types.dart';

/// What a spelling answer was, judged against the author's closed list for the item (docs/languages/frame.md section 3.3.5):
/// the book spelling, a spelling that writes every sound and that the author listed, or neither. The list is never worked
/// out at run time.
enum SpellingOutcome { exact, soundRight, notYet }

/// The answer field `detail` for the parent view ("spells every sound; learning book spelling"). The wire word is
/// [wire]: `exact`, `sound_right`, or empty when the answer was not a spelling that was judged.
enum SpellingDetail {
  none(''),
  exact('exact'),
  soundRight('sound_right');

  const SpellingDetail(this.wire);

  final String wire;
}

/// How the engine takes one spelling answer.
class ScoredSpelling {
  const ScoredSpelling({
    required this.result,
    required this.detail,
    required this.countsAsMisconception,
    required this.onTheWay,
  });

  /// The engine stays three-valued: this is what is written as the answer's result.
  final Result result;
  final SpellingDetail detail;

  /// The tag of the answer is evidence of a misconception (the engine counts it because the result is incorrect).
  final bool countsAsMisconception;

  /// The answer is right by sound where the skill does not ask for the convention yet: the tag is kept as "on the way", with
  /// no misconception evidence and no lowering of the estimate.
  final bool onTheWay;
}

/// The result of a spelling answer in a skill with the given [policy]:
///
/// - the book spelling is correct;
/// - an answer that is right by sound is `correct` and "on the way" where the skill accepts it, and `incorrect` with the tag
///   as misconception evidence where the skill teaches the convention;
/// - anything else is incorrect, as always.
///
/// The child's feedback names what is right first in every case, and an answer that is right by sound is never called wrong:
/// that is the template's job; this function only decides what the engine is told.
ScoredSpelling scoreSpelling(SpellingOutcome outcome, SoundRightPolicy policy) => switch (outcome) {
  SpellingOutcome.exact => const ScoredSpelling(
    result: Result.correct,
    detail: SpellingDetail.exact,
    countsAsMisconception: false,
    onTheWay: false,
  ),
  SpellingOutcome.soundRight when policy == SoundRightPolicy.accepts => const ScoredSpelling(
    result: Result.correct,
    detail: SpellingDetail.soundRight,
    countsAsMisconception: false,
    onTheWay: true,
  ),
  SpellingOutcome.soundRight => const ScoredSpelling(
    result: Result.incorrect,
    detail: SpellingDetail.soundRight,
    countsAsMisconception: true,
    onTheWay: false,
  ),
  SpellingOutcome.notYet => const ScoredSpelling(
    result: Result.incorrect,
    detail: SpellingDetail.none,
    countsAsMisconception: true,
    onTheWay: false,
  ),
};
