// The placement staircase of the language courses (docs/languages/frame.md section 3.2, LS13; docs/curriculum.md section 10.1). Pure
// functions and plain classes: no clock, no database, no widget. A course defines its strands, each a ladder of levels with probe items;
// the staircase of a strand moves by the answers it is given, and the placement is read from what was answered, so replaying the
// recorded answers gives the same placement as playing them did.
//
// The rules, exactly as the frame states them:
// - two right answers go up a level, one wrong answer goes down;
// - a strand stops after 2 reversals or 8 items;
// - the placement is the highest level with at least two thirds right, minus one unit;
// - a strand whose first two probes fail at its floor stops at once, so a beginner never gets 8 failures;
// - a questionnaire answer sets where a staircase starts, never where it ends;
// - the strands run across the first visits, oral first, never more than about 8 probe items in one visit;
// - speech is never a probe (the items are taps), and no result is shown to the child.

/// The ladder of one strand: its levels from the floor up, each with the ids of its probe items, and the level it starts at.
class StrandPlan {
  const StrandPlan({required this.id, required this.levels, this.start = 0});

  final String id;

  /// The probe items of each level, easiest level first. A level has at least one.
  final List<List<String>> levels;

  /// The level the staircase starts at: the questionnaire's answer (the floor when there is none).
  final int start;

  StrandPlan startingAt(int level) =>
      StrandPlan(id: id, levels: levels, start: level.clamp(0, levels.length - 1));
}

/// What a strand's staircase found.
class StrandResult {
  const StrandResult({required this.entry, required this.best, required this.stopped, required this.asked});

  /// The level the course starts at for this strand ("we start here"): the highest level with at least two thirds right, minus one
  /// unit, and never below the floor.
  final int entry;

  /// The highest level with at least two thirds right, or null when no level qualified.
  final int? best;

  /// The staircase has stopped (it takes no more probes).
  final bool stopped;

  /// How many probes it was given.
  final int asked;
}

/// The staircase of one strand.
class Staircase {
  Staircase(this.plan) : level = plan.start.clamp(0, plan.levels.length - 1);

  /// At most this many probes for one strand.
  static const int mostItems = 8;

  /// The strand stops after this many reversals (a move up after a move down, or the other way round).
  static const int mostReversals = 2;

  /// A strand stops at once when this many probes in a row are missed at its floor.
  static const int floorMisses = 2;

  final StrandPlan plan;

  /// The level the next probe is taken from.
  int level;

  /// Right answers in a row at this level (two go up).
  int _run = 0;
  int _reversals = 0;
  int _lastMove = 0;
  int _floorMissed = 0;
  bool _ceiling = false;
  final List<({String item, int level, bool right})> _asked = <({String item, int level, bool right})>[];

  int get asked => _asked.length;
  int get reversals => _reversals;

  /// The next probe's id, or null when the strand has stopped: its eight, its two reversals, two misses at the floor, the top of the
  /// ladder passed twice, or no probe left at the level it is on.
  String? get next {
    if (_asked.length >= mostItems ||
        _reversals >= mostReversals ||
        _floorMissed >= floorMisses ||
        _ceiling) {
      return null;
    }
    for (final String item in plan.levels[level]) {
      if (!_asked.any((({String item, int level, bool right}) a) => a.item == item)) return item;
    }
    return null;
  }

  bool get stopped => next == null;

  /// The probe [item] was answered, right or not. A probe the staircase did not hand out is still counted at its own level.
  void record(String item, {required bool right}) {
    final int own = _levelOf(item) ?? level;
    _asked.add((item: item, level: own, right: right));
    if (right) {
      _floorMissed = 0;
      _run++;
      if (_run >= 2) {
        _run = 0;
        if (level == plan.levels.length - 1) {
          _ceiling = true;
        } else {
          _move(1);
        }
      }
    } else {
      _run = 0;
      if (level == 0) {
        _floorMissed++;
      } else {
        _move(-1);
      }
    }
  }

  void _move(int direction) {
    if (_lastMove != 0 && _lastMove != direction) _reversals++;
    _lastMove = direction;
    level += direction;
  }

  int? _levelOf(String item) {
    for (final (int i, List<String> items) in plan.levels.indexed) {
      if (items.contains(item)) return i;
    }
    return null;
  }

  /// The placement from what was answered so far.
  StrandResult get result {
    int? best;
    for (int l = 0; l < plan.levels.length; l++) {
      final Iterable<({String item, int level, bool right})> at = _asked.where(
        (({String item, int level, bool right}) a) => a.level == l,
      );
      if (at.isEmpty) continue;
      final int right = at.where((({String item, int level, bool right}) a) => a.right).length;
      if (right * 3 >= at.length * 2) best = l;
    }
    // A strand stopped by two misses at its floor places at the floor, whatever else was right.
    final int entry = _floorMissed >= floorMisses || best == null ? 0 : (best - 1 < 0 ? 0 : best - 1);
    return StrandResult(entry: entry, best: best, stopped: stopped, asked: _asked.length);
  }
}

/// The whole placement game of a course: the staircases of its strands, played one after another (the first strand first, so the oral
/// strand comes before literacy), with at most [perVisit] probes in one visit.
class PlacementGame {
  PlacementGame({required this.strands, this.perVisit = 8}) {
    for (final StrandPlan s in strands) {
      _stairs[s.id] = Staircase(s);
      for (final (int l, List<String> items) in s.levels.indexed) {
        for (final String item in items) {
          _owner[item] = (strand: s.id, level: l);
        }
      }
    }
  }

  /// The strands that are offered to this child, in the order they are played.
  final List<StrandPlan> strands;

  /// Never more than about this many probes in one visit.
  final int perVisit;

  final Map<String, Staircase> _stairs = <String, Staircase>{};
  final Map<String, ({String strand, int level})> _owner = <String, ({String strand, int level})>{};

  Staircase? stairs(String strand) => _stairs[strand];

  /// Which strand and level a probe belongs to, or null for an id that is no probe of this game.
  ({String strand, int level})? whereIs(String item) => _owner[item];

  /// The probe to give next, or null when the visit is full ([doneThisVisit] probes were given in it) or every strand has stopped.
  String? next({int doneThisVisit = 0}) {
    if (doneThisVisit >= perVisit) return null;
    for (final StrandPlan s in strands) {
      final String? item = _stairs[s.id]!.next;
      if (item != null) return item;
    }
    return null;
  }

  /// Every strand has stopped: the placement is finished.
  bool get complete => strands.every((StrandPlan s) => _stairs[s.id]!.stopped);

  /// Takes the answer to a probe. An id that is no probe of this game is ignored (an answer of another visit or another pack).
  void record(String item, {required bool right}) {
    final ({String strand, int level})? w = _owner[item];
    if (w != null) _stairs[w.strand]!.record(item, right: right);
  }

  /// The result of each strand, by strand id.
  Map<String, StrandResult> get results => <String, StrandResult>{
    for (final StrandPlan s in strands) s.id: _stairs[s.id]!.result,
  };
}
