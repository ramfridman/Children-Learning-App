import 'dart:isolate';

import 'alert_lists.dart';
import 'hebrew_text.dart';

/// The on-device word lists behind the parent's word alerts (PLAN: Alerts in v1). No model is involved: the
/// recogniser's text of a spoken answer is looked at once, on the phone, and only the alert (and, if the parent allows
/// it, the words that set it off) is kept.
///
/// Three tiers (docs/child-safety/alert-word-lists-proposed.md):
/// - **1, act**: a clear worrying statement. An important alert with a push.
/// - **2, check**: ambiguous or very common (siblings, films). An alert in the app only.
/// - **3, note**: swearing and words of the adult world, counted in a weekly note; never pushed.
///
/// Matching is exact on whole tokens after [alertNormalize]: there is **no phonetic or edit-distance matching** for these
/// lists (`phoneticKey('חרא')` is the key of `כל`, `קל` and `קר`). What it tolerates instead: the listed one-letter
/// prefixes, a doubled yod or vav, filler words inside a phrase, and parts in any order inside a window.
///
/// **Review needed.** The lists are a draft (`review: needs-editor`): an editor and a counsellor must read them before the
/// app is relied on, and the app never presents the alerts as protection.
class WordMatch {
  const WordMatch({
    required this.tier,
    required this.sub,
    required this.rule,
    required this.text,
    required this.listVersion,
    this.often = false,
    this.secret = false,
    this.swear,
  });

  /// 1 (act), 2 (check) or 3 (note).
  final int tier;

  /// PHYS, SEX, FEAR, NEGL, EMERG, SELF, ONLINE, SECRET, SWEAR or EXPOSE.
  final String sub;

  /// The row that matched (`W-01`, `S-01`).
  final String rule;

  /// The recogniser's hypothesis that matched, as it wrote it.
  final String text;

  /// The version of the lists that matched.
  final String listVersion;

  /// Rule C-5: the same answer says it happens often (`כל יום`, `חזק`).
  final bool often;

  /// Rule C-2: a secret and a harm in the same answer made this an act.
  final bool secret;

  /// Rule C-4: a swear word in the same answer as a phrase that won; it is still counted in the weekly note.
  final WordMatch? swear;
}

/// The recogniser's text as the lists are matched: [normalizeHebrew], and a run of yod or vav as one (`עליי` is `עלי`).
String alertNormalize(String text) =>
    normalizeHebrew(text).replaceAll(_doubleYod, 'י').replaceAll(_doubleVav, 'ו');

final RegExp _doubleYod = RegExp('י{2,}');
final RegExp _doubleVav = RegExp('ו{2,}');

/// What, if anything, the recogniser's [texts] (its hypotheses for one answer, best first) set off.
///
/// - [ageBand] is the child's band (0 to 2, ages 3–4, 5–6, 7–8): some rows change tier or are off by age.
/// - [answerWords] are the answers of the activity on screen (normalised): a swear word that is also an answer (the
///   letter name `זין`) is not a swear there.
/// - A tier 1 row counts in any hypothesis; tier 2 and 3 rows only in the best one, or in two of them.
/// - The strongest tier wins; a swear in the same answer as a phrase is passed on in [WordMatch.swear].
WordMatch? checkWords(
  Iterable<String> texts, {
  int ageBand = 1,
  Set<String> answerWords = const <String>{},
  AlertLists? lists,
}) => (lists ?? AlertLists.bundled).check(texts.toList(), ageBand: ageBand, answerWords: answerWords);

/// [checkWords] on another isolate, so a long answer or a heavy list never holds up a frame of the lesson (SEC-26). The
/// lists are compiled there once per call (a few milliseconds) unless [lists] are given.
Future<WordMatch?> checkWordsOffThread(
  List<String> texts, {
  int ageBand = 1,
  Set<String> answerWords = const <String>{},
  AlertLists? lists,
}) => Isolate.run(() => checkWords(texts, ageBand: ageBand, answerWords: answerWords, lists: lists));

/// The compiled lists. [AlertLists.fromJson] reads the shape of `bundledAlertLists` (and, later, of a signed pack).
class AlertLists {
  AlertLists._(
    this.listVersion,
    this._rules,
    this._words,
    this._neg,
    this._i,
    this._intense,
    this._prefixes, [
    this._floor = 0,
  ]);

  /// Reads lists of the shape of `bundledAlertLists`. Anything outside the schema (a value that would not fit an alert,
  /// a bound that would make matching slow, a wrong type, an unknown set or class) throws a [FormatException] (SEC-26).
  factory AlertLists.fromJson(Map<String, Object?> json) {
    try {
      final _Compiler c = _Compiler(json);
      final String version = _check(json['listVersion'], _versionPattern, 'listVersion');
      final List<Object?> rules = json['rules']! as List<Object?>;
      final List<Object?> words = json['words']! as List<Object?>;
      if (rules.length > _maxRows || words.length > _maxRows) throw const FormatException('too many rows');
      return AlertLists._(
        version,
        <_Rule>[for (final Object? r in rules) c.rule(r! as Map<String, Object?>)],
        <_WordRow>[for (final Object? w in words) c.wordRow(w! as Map<String, Object?>)],
        c.plainSet('NEG'),
        c.plainSet('I'),
        c.slot('@INTENSE'),
        c.allPrefixes,
      );
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('bad alert lists: ${e.runtimeType}');
    }
  }

  /// Lists from another source (a signed pack, later), or the app's own when that source cannot be read or is older than
  /// the app's. Every loaded list keeps the app's own tier 1 rows as a floor: a source can add acts, never take them away.
  /// The floor is checked first and has a step budget of its own, so a larger list can never spend the budget before the
  /// floor is looked at (SEC-26). Never throws.
  static AlertLists load(Object? json) {
    try {
      final AlertLists l = AlertLists.fromJson(json! as Map<String, Object?>);
      if (_compareVersions(l.listVersion, bundled.listVersion) < 0) return bundled;
      final List<_Rule> floor = <_Rule>[...bundled._rules.where((_Rule r) => r.tiers.contains(1))];
      return AlertLists._(
        l.listVersion,
        <_Rule>[...floor, ...l._rules],
        l._words,
        l._neg,
        l._i,
        l._intense,
        <String>{...l._prefixes, ...bundled._prefixes}.toList()
          ..sort((String a, String b) => b.length.compareTo(a.length)),
        floor.length,
      );
    } on Object {
      return bundled;
    }
  }

  /// The lists in this build of the app.
  static final AlertLists bundled = AlertLists.fromJson(bundledAlertLists);

  /// A hypothesis longer than twice this many tokens is looked at only at its start and its end (an answer is at most
  /// 8 seconds of speech; this bounds the work for anything else).
  static const int maxTokens = 120;

  /// The most matching steps one check may take; past it the rest of that check finds nothing (a list that would make
  /// matching slow, SEC-26). A real answer takes a small part of it.
  static const int stepBudget = 200000;

  static final RegExp _versionPattern = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}\.[0-9]{1,3}$');
  static const int _maxRows = 300;

  static int _compareVersions(String a, String b) {
    final List<String> x = a.split('.');
    final List<String> y = b.split('.');
    final int day = x.first.compareTo(y.first);
    return day != 0 ? day : int.parse(x.last).compareTo(int.parse(y.last));
  }

  final String listVersion;
  final List<_Rule> _rules;
  final List<_WordRow> _words;
  final Set<String> _neg;

  /// `אני`: the child as the subject.
  final Set<String> _i;
  final _Slot _intense;

  /// Every prefix of every class, longest first: a token is split by each once per hypothesis.
  final List<String> _prefixes;

  /// How many of the first [_rules] are the app's own floor (they have a step budget of their own).
  final int _floor;

  static const Set<String> _harm = <String>{'PHYS', 'SEX', 'FEAR'};

  WordMatch? check(List<String> texts, {required int ageBand, required Set<String> answerWords}) {
    final List<_Hit> hits = <_Hit>[];
    final _Budget budget = _Budget(stepBudget);
    final _Budget floorBudget = _Budget(stepBudget);
    final Set<String> answers = <String>{for (final String a in answerWords) ...tokensOf(normalizeHebrew(a))};
    for (int h = 0; h < texts.length; h++) {
      final List<_Text> parts = _textsOf(texts[h], budget);
      final List<_Text> floorParts = _floor == 0 ? parts : _textsOf(texts[h], floorBudget);
      for (int r = 0; r < _rules.length; r++) {
        final int tier = _rules[r].tierFor(ageBand);
        final List<_Text> mine = r < _floor ? floorParts : parts;
        if (tier > 0 && mine.any((_Text t) => _rules[r].mayMatch(t) && _rules[r].matches(t))) {
          hits.add(_Hit(h, tier, r, null));
        }
      }
      // Swear words are matched on the plain text: collapsing yods would turn `מזיין` into `מזין` ("nourishing").
      final List<List<String>> plain = <List<String>>[
        for (final List<String> part in _capped(tokensOf(normalizeHebrew(texts[h]))))
          <String>[for (final String w in part) answers.contains(w) ? '' : w],
      ];
      for (int w = 0; w < _words.length; w++) {
        if (plain.any(_words[w].matches)) hits.add(_Hit(h, 3, null, w));
      }
    }
    // Tier 2 and 3 need the best hypothesis or two hypotheses with the same row (a mis-hearing rarely repeats).
    final List<_Hit> counted = <_Hit>[
      for (final _Hit x in hits)
        if (x.tier == 1 || x.hyp == 0 || hits.where((_Hit y) => y.sameRow(x) && y.hyp != x.hyp).isNotEmpty) x,
    ];
    if (counted.isEmpty) return null;
    counted.sort(_stronger);
    _Hit best = counted.first;
    bool secret = false;
    // C-2: a secret together with a harm in the same answer is an act about the harm.
    final _Hit? harm = counted.where((_Hit x) => _harm.contains(_subOf(x))).firstOrNull;
    if (harm != null && counted.any((_Hit x) => _subOf(x) == 'SECRET')) {
      if (best.tier > 1) best = _Hit(harm.hyp, 1, harm.rule, harm.word);
      secret = _harm.contains(_subOf(best));
    }
    final _Hit? swore = counted.where((_Hit x) => x.word != null && x != best).firstOrNull;
    final String text = texts[best.hyp];
    final String sub = _subOf(best);
    return WordMatch(
      tier: best.tier,
      sub: sub,
      rule: _idOf(best),
      text: text,
      listVersion: listVersion,
      often: _harm.contains(sub) && _textsOf(text, _Budget(stepBudget)).any(_intense.foundIn),
      secret: secret,
      swear: swore == null || best.word != null
          ? null
          : WordMatch(
              tier: 3,
              sub: _subOf(swore),
              rule: _idOf(swore),
              text: texts[swore.hyp],
              listVersion: listVersion,
            ),
    );
  }

  /// The strongest tier, then the best hypothesis, then the more specific row (more parts: online bullying in a chat
  /// group before bullying, QA-38), then the order of the table.
  int _stronger(_Hit a, _Hit b) {
    if (a.tier != b.tier) return a.tier - b.tier;
    if (a.hyp != b.hyp) return a.hyp - b.hyp;
    int parts(_Hit x) => x.rule == null ? 0 : _rules[x.rule!].parts;
    if (parts(a) != parts(b)) return parts(b) - parts(a);
    int order(_Hit x) => x.rule ?? _rules.length + x.word!;
    return order(a) - order(b);
  }

  /// The tokens of a hypothesis, at most [maxTokens] from its start and as many from its end.
  static List<List<String>> _capped(List<String> tokens) => tokens.length <= 2 * maxTokens
      ? <List<String>>[tokens]
      : <List<String>>[tokens.sublist(0, maxTokens), tokens.sublist(tokens.length - maxTokens)];

  List<_Text> _textsOf(String text, _Budget budget) => <_Text>[
    for (final List<String> part in _capped(tokensOf(alertNormalize(text))))
      _Text(part, _neg, _i, _prefixes, budget),
  ];

  String _subOf(_Hit x) => x.rule != null ? _rules[x.rule!].sub : _words[x.word!].sub;
  String _idOf(_Hit x) => x.rule != null ? _rules[x.rule!].id : _words[x.word!].id;
}

/// One row found in one hypothesis: a phrase rule ([rule]) or a swear row ([word]).
class _Hit {
  const _Hit(this.hyp, this.tier, this.rule, this.word);

  final int hyp;
  final int tier;
  final int? rule;
  final int? word;

  bool sameRow(_Hit o) => o.rule == rule && o.word == word;
}

/// The steps left to one check.
class _Budget {
  _Budget(this.left);

  int left;

  /// One more step, or false when there are none left.
  bool spend() => --left >= 0;
}

/// The tokens of one hypothesis, with the few sets every rule looks at. Each token is split once into the word itself
/// and the word after each prefix it may carry ([splits]); [words] holds all of them, so a rule whose first words are
/// nowhere in the text is skipped without a scan.
class _Text {
  _Text(this.tokens, this.neg, this.i, List<String> prefixes, this.budget)
    : splits = <List<(String, String)>>[
        for (final String w in tokens)
          <(String, String)>[
            ('', w),
            for (final String p in prefixes)
              if (w.length > p.length && w.startsWith(p)) (p, w.substring(p.length)),
          ],
      ] {
    for (final List<(String, String)> s in splits) {
      for (final (String _, String word) in s) {
        words.add(word);
      }
    }
  }

  final List<String> tokens;
  final Set<String> neg;
  final Set<String> i;
  final _Budget budget;
  final List<List<(String, String)>> splits;
  final Set<String> words = <String>{};

  int get length => tokens.length;

  bool isNeg(int at) => at >= 0 && at < tokens.length && neg.contains(tokens[at]);
}

/// One token of a pattern: exact forms, and stems (`ב*`) that match any longer word.
class _Tok {
  _Tok(this.forms, this.stems);

  final Set<String> forms;
  final List<String> stems;

  bool test(String w) => forms.contains(w) || stems.any((String s) => w.length > s.length && w.startsWith(s));
}

/// A run of tokens; the first may carry one of [prefixes] and may not follow one of [notAfter].
class _Alt {
  _Alt(this.tokens, this.prefixes, this.notAfter);

  final List<_Tok> tokens;
  final List<String> prefixes;
  final Set<String> notAfter;

  bool headAt(_Text t, int at) {
    if (at > 0 && notAfter.contains(t.tokens[at - 1])) return false;
    final String w = t.tokens[at];
    if (tokens.first.test(w)) return true;
    for (final String p in prefixes) {
      if (w.length > p.length && w.startsWith(p) && tokens.first.test(w.substring(p.length))) return true;
    }
    return false;
  }

  /// Every way this run matches from [at], with at most [gap] filler tokens (never a negation) between its tokens.
  /// Each result is the positions used and the fillers spent.
  Iterable<({List<int> used, int spent})> matchAt(_Text t, int at, int gap) sync* {
    if (!headAt(t, at)) return;
    yield* _rest(t, 1, <int>[at], gap, 0);
  }

  Iterable<({List<int> used, int spent})> _rest(_Text t, int k, List<int> used, int gap, int spent) sync* {
    if (!t.budget.spend()) return;
    if (k == tokens.length) {
      yield (used: used, spent: spent);
      return;
    }
    for (int skip = 0; skip <= gap - spent; skip++) {
      final int at = used.last + 1 + skip;
      if (at >= t.length) return;
      if (skip > 0 && t.isNeg(at - 1)) return;
      if (tokens[k].test(t.tokens[at])) yield* _rest(t, k + 1, <int>[...used, at], gap, spent + skip);
    }
  }
}

/// A place in a pattern: one of several runs, perhaps missing. The runs are indexed by their first word, so a token is
/// looked up a few times (bare and without each prefix) instead of being compared with every word of a set.
class _Slot {
  _Slot(List<_Alt> alts, {this.optional = false}) {
    for (final _Alt a in alts) {
      for (final String f in a.tokens.first.forms) {
        (_heads[f] ??= <_Alt>[]).add(a);
      }
      if (a.tokens.first.stems.isNotEmpty) _stemmed.add(a);
      _prefixes.addAll(a.prefixes);
    }
  }

  final bool optional;
  final Map<String, List<_Alt>> _heads = <String, List<_Alt>>{};
  final List<_Alt> _stemmed = <_Alt>[];
  final Set<String> _prefixes = <String>{};

  /// The words a match of this slot starts with, or null when a stem (`ב*`) can start one.
  Set<String>? get firstWords => _stemmed.isEmpty ? _heads.keys.toSet() : null;

  Iterable<({List<int> used, int spent})> matchAt(_Text t, int at, int gap) sync* {
    for (final (String p, String word) in t.splits[at]) {
      if (p.isNotEmpty && !_prefixes.contains(p)) continue;
      for (final _Alt a in _heads[word] ?? const <_Alt>[]) {
        yield* a.matchAt(t, at, gap);
      }
    }
    for (final _Alt a in _stemmed) {
      yield* a.matchAt(t, at, gap);
    }
  }

  /// Every match inside positions [lo] to [hi].
  Iterable<List<int>> within(_Text t, int lo, int hi) sync* {
    for (int at = lo < 0 ? 0 : lo; at <= hi && at < t.length; at++) {
      for (final ({List<int> used, int spent}) m in matchAt(t, at, 1)) {
        if (m.used.last <= hi) yield m.used;
      }
    }
  }

  bool foundIn(_Text t) => within(t, 0, t.length - 1).isNotEmpty;
}

class _Rule {
  _Rule({
    required this.id,
    required this.sub,
    required this.tiers,
    required this.slots,
    required this.window,
    required this.gap,
    required this.need,
    required this.avoid,
    required this.near,
    required this.after,
    required this.afterWin,
    required this.neg,
    required this.noI,
  });

  final String id;
  final String sub;

  /// The tier for bands A, B and C (0 = off).
  final List<int> tiers;
  final List<_Slot> slots;

  /// A window rule: every slot within this many tokens of the first; null for a fixed phrase.
  final int? window;
  final int gap;
  final List<_Slot> need;
  final List<_Slot> avoid;
  final int near;
  final List<_Slot> after;
  final int afterWin;
  final bool neg;
  final bool noI;

  int tierFor(int band) => tiers[band.clamp(0, 2)];

  /// How specific the row is: its slots and the parts it needs near them.
  int get parts => slots.length + need.length;

  /// The words the first slot that must be there starts with (null: no quick test).
  late final Set<String>? _firstWords = slots.where((_Slot s) => !s.optional).firstOrNull?.firstWords;

  /// False when the rule cannot match: none of its first words is in the text.
  bool mayMatch(_Text t) {
    final Set<String>? first = _firstWords;
    if (first == null) return true;
    return first.length < t.words.length ? first.any(t.words.contains) : t.words.any(first.contains);
  }

  bool matches(_Text t) {
    for (int at = 0; at < t.length; at++) {
      if (window == null ? _seqFrom(t, at) : _windowFrom(t, at)) return true;
    }
    return false;
  }

  bool _before(_Text t, int start) {
    if (neg && (t.isNeg(start - 1) || t.isNeg(start - 2))) return false;
    if (noI && start > 0 && t.i.contains(t.tokens[start - 1])) return false;
    return true;
  }

  bool _around(_Text t, List<int> used) {
    final int lo = used.reduce((int a, int b) => a < b ? a : b);
    final int hi = used.reduce((int a, int b) => a > b ? a : b);
    for (final _Slot s in need) {
      if (s.within(t, lo - near, hi + near).isEmpty) return false;
    }
    for (final _Slot s in avoid) {
      if (s.within(t, lo - near, hi + near).isNotEmpty) return false;
    }
    for (final _Slot s in after) {
      if (s.within(t, hi + 1, hi + afterWin).isNotEmpty) return false;
    }
    return true;
  }

  // ---- a fixed phrase: the slots in order, at most [gap] fillers in all ----
  bool _seqFrom(_Text t, int start) {
    if (!_before(t, start)) return false;
    return _seq(t, 0, start, true, <int>[], 0);
  }

  bool _seq(_Text t, int k, int from, bool first, List<int> used, int spent) {
    if (!t.budget.spend()) return false;
    if (k == slots.length) return used.isNotEmpty && _around(t, used);
    final _Slot s = slots[k];
    for (int skip = 0; skip <= (first ? 0 : gap - spent); skip++) {
      final int at = from + skip;
      if (at >= t.length) break;
      if (skip > 0 && t.isNeg(at - 1)) break;
      for (final ({List<int> used, int spent}) m in s.matchAt(t, at, gap - spent - skip)) {
        final List<int> next = <int>[...used, ...m.used];
        if (_seq(t, k + 1, m.used.last + 1, false, next, spent + skip + m.spent)) return true;
      }
    }
    // A missing slot: the next one starts where this one would have.
    return s.optional && _seq(t, k + 1, from, first, used, spent);
  }

  // ---- a window: the first slot is the anchor, every other within [window] tokens of it, no token used twice ----
  bool _windowFrom(_Text t, int at) {
    for (final ({List<int> used, int spent}) anchor in slots.first.matchAt(t, at, 1)) {
      if (!_before(t, at)) continue;
      final int lo = anchor.used.first - window!;
      final int hi = anchor.used.last + window!;
      if (_parts(t, 1, lo, hi, anchor.used)) return true;
    }
    return false;
  }

  bool _parts(_Text t, int k, int lo, int hi, List<int> used) {
    if (!t.budget.spend()) return false;
    if (k == slots.length) return _around(t, used);
    for (final List<int> m in slots[k].within(t, lo, hi)) {
      if (m.any(used.contains)) continue;
      if (_parts(t, k + 1, lo, hi, <int>[...used, ...m])) return true;
    }
    return false;
  }
}

/// A swear row: whole tokens, or a short run of them with nothing between.
class _WordRow {
  _WordRow(this.id, this.sub, this.forms, this.notAfter);

  final String id;
  final String sub;
  final List<List<String>> forms;
  final Set<String> notAfter;

  bool matches(List<String> tokens) {
    for (int i = 0; i < tokens.length; i++) {
      if (i > 0 && notAfter.contains(tokens[i - 1])) continue;
      for (final List<String> f in forms) {
        if (i + f.length > tokens.length) continue;
        bool all = true;
        for (int j = 0; j < f.length && all; j++) {
          all = tokens[i + j] == f[j];
        }
        if (all) return true;
      }
    }
    return false;
  }
}

/// [v] as a string in [pattern], or a [FormatException] naming [what].
String _check(Object? v, RegExp pattern, String what) {
  final String s = v! as String;
  if (!pattern.hasMatch(s)) throw FormatException('bad $what');
  return s;
}

/// Reads the JSON shape of the lists into slots and rules. Every word goes through [alertNormalize], as the text does.
class _Compiler {
  _Compiler(Map<String, Object?> json)
    : _prefixes = <String, List<String>>{
        for (final MapEntry<String, Object?> e in (json['prefixes']! as Map<String, Object?>).entries)
          e.key: <String>[for (final Object? p in e.value! as List<Object?>) p! as String],
      },
      _sets = json['sets']! as Map<String, Object?> {
    for (final List<String> p in _prefixes.values) {
      for (final String x in p) {
        if (!_prefixPattern.hasMatch(x)) throw FormatException('bad prefix "$x"');
      }
    }
  }

  final Map<String, List<String>> _prefixes;
  final Map<String, Object?> _sets;

  static const int _maxWord = 32;
  static const int _maxAltTokens = 6;
  static const int _maxEntries = 6000;
  static const int _maxSlots = 8;

  /// A window's parts are matched in any order, which grows fast with their number (SEC-26).
  static const int _maxWindowSlots = 4;
  static const int _maxGuards = 4;
  static const Set<String> _subs = <String>{
    'PHYS', 'SEX', 'FEAR', 'NEGL', 'EMERG', 'SELF', 'ONLINE', 'SECRET', 'SWEAR', 'EXPOSE', //
  };
  static final RegExp _idPattern = RegExp(r'^[A-Z]{1,3}-[0-9]{2,3}$');
  static final RegExp _prefixPattern = RegExp('^[\u05d0-\u05ea]{1,3}\$');

  /// Run entries made so far: a set used in many slots counts each time (the work it makes).
  int _entries = 0;

  /// Every prefix of every class, each once, longest first.
  List<String> get allPrefixes =>
      <String>{for (final List<String> p in _prefixes.values) ...p}.toList()
        ..sort((String a, String b) => b.length.compareTo(a.length));

  Map<String, Object?> _set(String name) {
    final Object? s = _sets[name];
    if (s == null) throw FormatException('unknown alert word set $name');
    return s as Map<String, Object?>;
  }

  List<String> _words(Map<String, Object?> set) => <String>[
    for (final Object? w in set['words']! as List<Object?>) w! as String,
  ];

  Set<String> plainSet(String name) => <String>{for (final String w in _words(_set(name))) alertNormalize(w)};

  List<String> _prefixesOf(String? cls) {
    if (cls == null) return const <String>[];
    final List<String>? p = _prefixes[cls];
    if (p == null) throw FormatException('unknown prefix class $cls');
    return p;
  }

  _Tok _tok(String spec) {
    final Set<String> forms = <String>{};
    final List<String> stems = <String>[];
    for (final String w in spec.split('/')) {
      final bool stem = w.endsWith('*');
      final String word = alertNormalize(stem ? w.substring(0, w.length - 1) : w);
      // An empty stem would match every word; a word of one token is never longer than this.
      if (word.isEmpty || word.contains(' ') || word.length > _maxWord) {
        throw FormatException('bad word "$w"');
      }
      if (stem) {
        stems.add(word);
      } else {
        forms.add(word);
      }
    }
    return _Tok(forms, stems);
  }

  _Alt _alt(String spec, List<String> prefixes, Set<String> notAfter) {
    final List<String> tokens = spec.split(' ');
    if (tokens.length > _maxAltTokens) throw FormatException('too long: "$spec"');
    if ((_entries += 1) > _maxEntries) throw const FormatException('too many words');
    return _Alt(<_Tok>[for (final String t in tokens) _tok(t)], prefixes, notAfter);
  }

  /// `alt|alt|@SET|@SET^class`, with `?` at the end when the slot may be missing. [pre] is the prefix class of the
  /// inline words.
  _Slot slot(String spec, {String? pre}) {
    final bool optional = spec.endsWith('?');
    final String body = optional ? spec.substring(0, spec.length - 1) : spec;
    final List<_Alt> alts = <_Alt>[];
    for (final String a in body.split('|')) {
      if (a.startsWith('@')) {
        final List<String> name = a.substring(1).split('^');
        final Map<String, Object?> set = _set(name.first);
        final List<String> prefixes = _prefixesOf(name.length > 1 ? name[1] : set['pre'] as String?);
        final Set<String> notAfter = <String>{
          for (final Object? w in set['notAfter'] as List<Object?>? ?? const <Object?>[])
            alertNormalize(w! as String),
        };
        for (final String w in _words(set)) {
          alts.add(_alt(w, prefixes, notAfter));
        }
      } else {
        alts.add(_alt(a, _prefixesOf(pre), const <String>{}));
      }
    }
    return _Slot(alts, optional: optional);
  }

  List<_Slot> _slots(Object? specs) {
    final List<Object?> list = specs as List<Object?>? ?? const <Object?>[];
    if (list.length > _maxGuards) throw const FormatException('too many guard slots');
    return <_Slot>[for (final Object? s in list) slot(s! as String)];
  }

  static int _bounded(Object? v, int fallback, int lo, int hi, String what) {
    final int x = v as int? ?? fallback;
    if (x < lo || x > hi) throw FormatException('$what out of bounds');
    return x;
  }

  static String _sub(Object? v) {
    final String sub = v! as String;
    if (!_subs.contains(sub)) throw FormatException('unknown sub $sub');
    return sub;
  }

  _Rule rule(Map<String, Object?> r) {
    final bool isWindow = r['win'] != null;
    final List<Object?> specs = (isWindow ? r['all'] : r['seq'])! as List<Object?>;
    if (specs.isEmpty || specs.length > (isWindow ? _maxWindowSlots : _maxSlots)) {
      throw const FormatException('slots out of bounds');
    }
    if (r['pre'] != null) _prefixesOf(r['pre']! as String);
    final int? tier = r['tier'] as int?;
    final List<int> tiers = tier != null
        ? <int>[tier, tier, tier]
        : <int>[for (final Object? x in r['tiers']! as List<Object?>) x! as int];
    if (tiers.length != 3 || tiers.any((int x) => x < 0 || x > 3)) {
      throw FormatException('bad tiers in ${r['id']}');
    }
    return _Rule(
      id: _check(r['id'], _idPattern, 'id'),
      sub: _sub(r['sub']),
      tiers: tiers,
      slots: <_Slot>[
        for (int i = 0; i < specs.length; i++)
          slot(specs[i]! as String, pre: i == 0 ? r['pre'] as String? : null),
      ],
      window: isWindow ? _bounded(r['win'], 0, 1, 5, 'win') : null,
      gap: _bounded(r['gap'], 1, 0, 2, 'gap'),
      need: _slots(r['with']),
      avoid: _slots(r['without']),
      near: _bounded(r['near'], 0, 0, 5, 'near'),
      after: _slots(r['after']),
      afterWin: _bounded(r['afterWin'], 2, 0, 3, 'afterWin'),
      neg: r['neg'] as bool? ?? false,
      noI: r['noI'] as bool? ?? false,
    );
  }

  _WordRow wordRow(Map<String, Object?> w) {
    final List<List<String>> forms = <List<String>>[
      for (final Object? f in w['forms']! as List<Object?>) tokensOf(normalizeHebrew(f! as String)),
    ];
    if (forms.isEmpty) throw const FormatException('a word row without forms');
    for (final List<String> f in forms) {
      if (f.isEmpty || f.length > _maxAltTokens || f.any((String t) => t.length > _maxWord)) {
        throw FormatException('bad form in ${w['id']}');
      }
      if ((_entries += 1) > _maxEntries) throw const FormatException('too many words');
    }
    return _WordRow(_check(w['id'], _idPattern, 'id'), _sub(w['sub']), forms, <String>{
      for (final Object? n in w['notAfter'] as List<Object?>? ?? const <Object?>[])
        normalizeHebrew(n! as String),
    });
  }
}
