// Decides what a child said, among the answers an activity expects. Pure Dart.
//
// The recogniser's text is never "the answer": it is compared with a short list of accepted words, and the
// outcome is one of four decisions. Unclear speech can only lead to `confirm`, `retry` or `noSpeech`, never to a
// wrong answer, and a spoken answer that matches a wrong option is always confirmed first.
import 'dart:math' as math;

import 'hebrew_text.dart';
import 'lexicon.dart';

/// One answer the activity expects, with the words that mean it.
class Expected {
  Expected.number(this.id, int n, {required this.correct}) : number = n, words = numberWords(n);

  Expected.colour(this.id, String colour, {required this.correct})
    : number = null,
      words = colourWords(colour);

  /// Free words (with or without niqqud), for the `speech` list an author gives an option.
  Expected.words(this.id, Iterable<String> forms, {required this.correct})
    : number = null,
      words = <AcceptWord>[for (final String f in forms) AcceptWord(normalizeHebrew(f))];

  final String id;
  final bool correct;
  final List<AcceptWord> words;

  /// The value, for a numeric answer: a spoken or written digit of this value matches exactly.
  final int? number;
}

/// One reading of the speech: the text and how sure the recogniser was (0 to 1).
class Hypothesis {
  const Hypothesis(this.text, this.confidence);

  final String text;
  final double confidence;
}

enum Decision {
  /// Clear: counts exactly like a tap.
  accept,

  /// Half heard, or a wrong option: the app asks "did you say ...?" and the child answers by tap or by "כן".
  confirm,

  /// Heard something, not an answer: ask again (and after two asks, invite a tap).
  retry,

  /// Nothing was said.
  noSpeech,
}

enum Why { clear, lowScore, closeCall, wrongNeedsConfirm, softMatch, negated, intent, silence }

class MatchResult {
  const MatchResult(this.decision, this.why, {this.optionId, this.intent, this.score = 0, this.margin = 0});

  final Decision decision;
  final Why why;

  /// The option that was matched (for `accept` and `confirm`).
  final String? optionId;

  /// A global intent (again, help, stop) heard instead of an answer.
  final Intent? intent;
  final double score;
  final double margin;

  @override
  String toString() =>
      'MatchResult($decision, $why, option: $optionId, intent: $intent, score: ${score.toStringAsFixed(2)})';
}

class MatcherConfig {
  const MatcherConfig({this.accept = 0.75, this.confirm = 0.5, this.margin = 0.12, this.softCap = 0.7});

  /// At or above this (and clear of the runner-up) the answer is taken.
  final double accept;

  /// Between this and [accept] the app asks "did you say ...?"; below it, nothing was understood.
  final double confirm;

  /// How far the best answer must be ahead of the next one.
  final double margin;

  /// The most a near miss (a soft word) can score, so it can never be accepted.
  final double softCap;
}

class AnswerMatcher {
  const AnswerMatcher({this.config = const MatcherConfig()});

  final MatcherConfig config;

  /// The intents that may be said instead of an answer.
  static const List<Intent> answerIntents = <Intent>[Intent.repeat, Intent.help, Intent.stop];

  MatchResult decide(List<Hypothesis> heard, List<Expected> expected) {
    final List<(String, double)> texts = <(String, double)>[
      for (final Hypothesis h in heard)
        if (normalizeHebrew(h.text).isNotEmpty) (normalizeHebrew(h.text), h.confidence.clamp(0.0, 1.0)),
    ];
    if (texts.isEmpty || expected.isEmpty) return const MatchResult(Decision.noSpeech, Why.silence);

    final Map<String, double> best = <String, double>{for (final Expected e in expected) e.id: 0};
    final Map<String, bool> bestSoft = <String, bool>{for (final Expected e in expected) e.id: false};
    double intentScore = 0;
    Intent? intent;
    bool negated = false;

    for (final (String text, double confidence) in texts) {
      final double f = math.sqrt(confidence);
      final List<String> tokens = tokensOf(text);

      // A global intent: the whole utterance compared with the phrases ("אני לא יודע", "עוד פעם").
      for (final Intent i in answerIntents) {
        for (final String phrase in intentPhrases(i)) {
          final double s = f * _phraseSimilarity(text, phrase);
          if (s > intentScore) {
            intentScore = s;
            intent = i;
          }
        }
      }
      final bool helpPhrase = intent == Intent.help && intentScore >= config.accept;

      // "לא שלוש" is the opposite of an answer.
      if (tokens.contains('לא') && !helpPhrase) negated = true;

      final Set<String> known = <String>{
        for (final Expected e in expected)
          for (final AcceptWord w in e.words) w.text,
      };
      final List<String> candidates = _candidates(tokens, known);
      for (final Expected e in expected) {
        for (final String c in candidates) {
          if (isDigits(c)) {
            final int? value = int.tryParse(c);
            if (value != null && e.number == value) {
              if (f > best[e.id]!) {
                best[e.id] = f;
                bestSoft[e.id] = false;
              }
            }
            continue;
          }
          for (final AcceptWord w in e.words) {
            if (isDigits(w.text)) continue;
            double s = similarity(c, w.text);
            if (w.soft) s = math.min(s, config.softCap / math.max(f, 0.01));
            final double score = f * s;
            if (score > best[e.id]!) {
              best[e.id] = score;
              bestSoft[e.id] = w.soft && s < 1;
            }
          }
        }
      }
    }

    final List<MapEntry<String, double>> ranked = best.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) => b.value.compareTo(a.value));
    final double top = ranked.first.value;
    final double second = ranked.length > 1 ? ranked[1].value : 0;

    // An intent wins when it is clear and at least as good as the best answer.
    if (intent != null && intentScore >= config.accept && intentScore >= top) {
      return MatchResult(Decision.accept, Why.intent, intent: intent, score: intentScore);
    }
    if (negated) return MatchResult(Decision.retry, Why.negated, score: top);
    if (top < config.confirm) return MatchResult(Decision.retry, Why.lowScore, score: top);

    final Expected winner = expected.firstWhere((Expected e) => e.id == ranked.first.key);
    final double margin = top - second;
    final bool soft = bestSoft[winner.id]!;
    if (top >= config.accept && margin >= config.margin && !soft) {
      // A mis-hearing must never cost the child a "not yet": a spoken wrong answer is checked first.
      if (!winner.correct) {
        return MatchResult(
          Decision.confirm,
          Why.wrongNeedsConfirm,
          optionId: winner.id,
          score: top,
          margin: margin,
        );
      }
      return MatchResult(Decision.accept, Why.clear, optionId: winner.id, score: top, margin: margin);
    }
    return MatchResult(
      Decision.confirm,
      soft ? Why.softMatch : (margin < config.margin ? Why.closeCall : Why.lowScore),
      optionId: winner.id,
      score: top,
      margin: margin,
    );
  }

  /// The answer to "did you say ...?": yes, no, or null when it was neither.
  Intent? confirmation(List<Hypothesis> heard) {
    double bestYes = 0;
    double bestNo = 0;
    for (final Hypothesis h in heard) {
      final String text = normalizeHebrew(h.text);
      if (text.isEmpty) continue;
      final double f = math.sqrt(h.confidence.clamp(0.0, 1.0));
      // "לא נכון" ends with "נכון" but means no.
      if (!tokensOf(text).contains('לא')) {
        for (final String p in intentPhrases(Intent.yes)) {
          bestYes = math.max(bestYes, f * _phraseSimilarity(text, p));
        }
      }
      for (final String p in intentPhrases(Intent.no)) {
        bestNo = math.max(bestNo, f * _phraseSimilarity(text, p));
      }
    }
    if (bestYes >= config.accept && bestYes > bestNo + config.margin) return Intent.yes;
    if (bestNo >= config.accept && bestNo > bestYes + config.margin) return Intent.no;
    return null;
  }

  /// The tokens, each token without one or two prefix letters, and each pair of neighbours (for "אחת עשרה").
  List<String> _candidates(List<String> tokens, Set<String> known) {
    final Set<String> out = <String>{};
    for (final String t in tokens) {
      out.add(t);
      String rest = t;
      for (int i = 0; i < 2; i++) {
        if (rest.isNotEmpty && prefixLetters.contains(rest[0]) && !isDigits(rest)) {
          rest = rest.substring(1);
          if (rest.length >= 3 || known.contains(rest)) out.add(rest);
        }
      }
    }
    for (int i = 0; i + 1 < tokens.length; i++) {
      out.add('${tokens[i]} ${tokens[i + 1]}');
    }
    return out.toList();
  }

  /// A phrase is matched when the utterance is the phrase, or ends with it ("אני לא יודע" for "לא יודע").
  double _phraseSimilarity(String utterance, String phrase) {
    double s = similarity(utterance, phrase);
    final List<String> u = tokensOf(utterance);
    final int n = tokensOf(phrase).length;
    if (u.length > n && u.length <= n + 2) {
      s = math.max(s, similarity(u.sublist(u.length - n).join(' '), phrase) * 0.97);
    }
    // A long utterance is not a short phrase.
    if (u.length > n + 2) s = 0;
    return s;
  }
}
