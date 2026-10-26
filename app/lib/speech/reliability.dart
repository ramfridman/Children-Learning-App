/// How well voice works for one child and one kind of answer, from the fixed words of their last listens.
/// When recognition keeps failing the app stops inviting voice (quietly: the mic simply is not offered), and tries
/// again after a week, because children and rooms change.
class VoiceListenRow {
  const VoiceListenRow(this.at, this.outcome);

  final DateTime at;

  /// `accepted`, `confirmed`, `declined`, `unclear`, `silent`, `intent` or `failed`.
  final String outcome;
}

const Set<String> _failures = <String>{'unclear', 'silent', 'failed', 'declined'};

/// Whether the mic should be offered now. [recentNewestFirst] are the child's latest listens for this kind of answer.
bool voiceWorks(
  List<VoiceListenRow> recentNewestFirst, {
  required DateTime now,
  int window = 6,
  int minListens = 4,
  double maxFailureShare = 0.67,
  Duration retryAfter = const Duration(days: 7),
}) {
  if (recentNewestFirst.length < minListens) return true;
  final List<VoiceListenRow> last = recentNewestFirst.take(window).toList();
  final int failed = last.where((VoiceListenRow r) => _failures.contains(r.outcome)).length;
  if (failed / last.length < maxFailureShare) return true;
  return now.difference(last.first.at) >= retryAfter;
}
