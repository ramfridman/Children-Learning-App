// The per-word matcher of the language courses (docs/languages/frame.md section 5.1, docs/milestones/L3.md).
//
// The question is never "what did the child say" but "did the child say the target, rather than one of the other things on
// screen". The answer has three values and none of them is "wrong": the child is either heard (confident), or the app cannot
// tell (unsure), or nothing was said (silence). Every cause of unsure gets the same kind reply, so the child is never told what
// the recogniser heard.
import '../engine/course.dart';
import 'word_text.dart';

/// What a word check can say. There is no value for a wrong word.
enum SayResult {
  /// The target (or one of its listed forms) was heard, clear of every foil.
  confident,

  /// Anything else: a foil said clearly, a mumble, noise, an accent the model missed, a word half heard.
  unsure,

  /// Nothing was recognised at all.
  silence,
}

/// The words of one item: the target and its listed forms, the foils, and for a chunk the key words that must each be heard.
/// All of it is signed content, never what a child or a tutor said.
class WordTarget {
  const WordTarget({
    required this.course,
    required this.forms,
    this.foils = const <String>[],
    this.keyWords = const <String>[],
  });

  final String course;

  /// The target word and the variants its teacher lists ("a cat" for cat, \u043c\u044f\u0447\u0438\u043a for \u043c\u044f\u0447). Any one of them is the target.
  final List<String> forms;

  /// The item's other options and the minimal-pair partner of the target (vet for wet, \u043b\u044e\u043a for \u043b\u0443\u043a).
  final List<String> foils;

  /// A chunk ("I'm happy"): every key word the author marks must be confident on its own. Empty for a single word.
  final List<String> keyWords;

  /// Every word the recogniser should be prepared for: the list for the hotwords (a chunk's key words, not the whole phrase).
  List<String> get hotwords => <String>[...forms, ...foils, ...keyWords];
}

/// How sure the matcher must be, per language.
class WordMatchConfig {
  const WordMatchConfig({required this.accept, required this.margin});

  /// The target's similarity to a reading must be at least this.
  final double accept;

  /// And ahead of the best foil by at least this.
  final double margin;

  /// From the spike (docs/milestones/L3.md section 7.3): 0 false-confident in 432 foil readings at these numbers.
  static const WordMatchConfig english = WordMatchConfig(accept: 0.75, margin: 0.15);

  /// Russian words are longer and the model is unmeasured on single words: a little stricter until the gate has data.
  static const WordMatchConfig russian = WordMatchConfig(accept: 0.8, margin: 0.15);

  /// Hebrew keeps the numbers of the existing matcher.
  static const WordMatchConfig hebrew = WordMatchConfig(accept: 0.75, margin: 0.12);

  static WordMatchConfig of(String course) => switch (course) {
    Course.eng => english,
    Course.rus => russian,
    _ => hebrew,
  };
}

/// The outcome with the numbers behind it, for tests and the PC tool. The numbers are never shown or stored.
class WordMatch {
  const WordMatch(this.result, {this.score = 0, this.margin = 0});

  final SayResult result;

  /// The best similarity of the target to anything read.
  final double score;

  /// How far the target is ahead of the best foil.
  final double margin;

  @override
  String toString() =>
      'WordMatch($result, score ${score.toStringAsFixed(2)}, margin ${margin.toStringAsFixed(2)})';
}

class WordMatcher {
  const WordMatcher({this.config});

  /// Null: the numbers of the target's course.
  final WordMatchConfig? config;

  /// Decides from [readings] (one or two texts from the recogniser; empty when it heard nothing).
  WordMatch decide(List<String> readings, WordTarget target) {
    final WordMatchConfig cfg = config ?? WordMatchConfig.of(target.course);
    final List<List<String>> heard = <List<String>>[
      for (final String r in readings)
        if (wordsOf(normalizeWords(target.course, r)).isNotEmpty) wordsOf(normalizeWords(target.course, r)),
    ];
    if (heard.isEmpty) return const WordMatch(SayResult.silence);

    final List<String> forms = _plain(target, target.forms);
    final List<String> foils = _plain(target, target.foils);
    // A foil that is the target (or a form of it) cannot be told apart from it: it is not a foil.
    foils.removeWhere(forms.contains);

    if (target.keyWords.isEmpty) {
      return _one(heard, forms, foils, cfg);
    }
    // A chunk: each key word must be heard on its own, clear of the foils.
    double worst = 1;
    double worstMargin = 1;
    for (final String key in _plain(target, target.keyWords)) {
      final WordMatch m = _one(heard, <String>[key], foils, cfg);
      if (m.result != SayResult.confident) {
        return WordMatch(SayResult.unsure, score: m.score, margin: m.margin);
      }
      if (m.score < worst) worst = m.score;
      if (m.margin < worstMargin) worstMargin = m.margin;
    }
    return WordMatch(SayResult.confident, score: worst, margin: worstMargin);
  }

  WordMatch _one(List<List<String>> heard, List<String> forms, List<String> foils, WordMatchConfig cfg) {
    final double best = _best(heard, forms);
    final double foil = _best(heard, foils);
    final double margin = best - foil;
    final bool sure = best >= cfg.accept && margin >= cfg.margin;
    return WordMatch(sure ? SayResult.confident : SayResult.unsure, score: best, margin: margin);
  }

  /// The best similarity of any of [words] to any run of the same number of words in any reading.
  double _best(List<List<String>> heard, List<String> words) {
    double best = 0;
    for (final String w in words) {
      final int n = wordsOf(w).length;
      for (final List<String> reading in heard) {
        for (int i = 0; i + n <= reading.length; i++) {
          final double s = wordSimilarity(reading.sublist(i, i + n).join(' '), w);
          if (s > best) best = s;
        }
      }
    }
    return best;
  }

  List<String> _plain(WordTarget t, List<String> words) => <String>[
    for (final String w in words)
      if (normalizeWords(t.course, w).isNotEmpty) normalizeWords(t.course, w),
  ];
}

/// "If more than 60% of the say-it turns of a visit come out unsure, the rest of that visit's say-it steps run as echo, with no
/// message" (frame section 5.1): a child is never asked to keep trying because a model struggles. Silence is not counted (the
/// child said nothing; the model did not fail), and nothing is decided before [minTurns] turns have been heard.
class QuietFallback {
  QuietFallback({this.minTurns = 3, this.share = 0.6});

  final int minTurns;
  final double share;
  int _heard = 0;
  int _unsure = 0;

  void record(SayResult r) {
    if (r == SayResult.silence) return;
    _heard++;
    if (r == SayResult.unsure) _unsure++;
  }

  /// The rest of this visit's say-it steps are echo.
  bool get echoOnly => _heard >= minTurns && _unsure / _heard > share;
}
