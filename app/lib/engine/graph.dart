import 'types.dart';

/// The skills as a directed graph (prerequisite to dependant). Built once from a catalogue; refuses a cycle.
class SkillGraph {
  SkillGraph(this.catalog) {
    for (final SkillNode s in catalog.skills.values) {
      for (final String p in s.prerequisites.keys) {
        (_dependants[p] ??= <String>{}).add(s.id);
      }
    }
    // Depth by walking down; also finds a cycle.
    final Set<String> done = <String>{};
    final Set<String> walking = <String>{};
    int visit(String id) {
      if (done.contains(id)) return _depth[id]!;
      if (!walking.add(id)) throw StateError('the skill graph has a cycle through $id');
      int d = 0;
      for (final String p in catalog.skills[id]!.prerequisites.keys) {
        if (!catalog.skills.containsKey(p)) throw StateError('$id needs a skill that does not exist: $p');
        final int pd = visit(p) + 1;
        if (pd > d) d = pd;
      }
      walking.remove(id);
      done.add(id);
      return _depth[id] = d;
    }

    for (final String id in catalog.skills.keys) {
      visit(id);
    }
  }

  final Catalog catalog;
  final Map<String, Set<String>> _dependants = <String, Set<String>>{};
  final Map<String, int> _depth = <String, int>{};

  SkillNode node(String id) => catalog.skills[id]!;

  /// 0 for a skill with no prerequisites.
  int depth(String id) => _depth[id]!;

  Set<String> dependantsOf(String id) => _dependants[id] ?? const <String>{};

  /// Every skill below [id] (prerequisites, their prerequisites, ...).
  Set<String> ancestors(String id) {
    final Set<String> out = <String>{};
    void walk(String s) {
      for (final String p in node(s).prerequisites.keys) {
        if (out.add(p)) walk(p);
      }
    }

    walk(id);
    return out;
  }

  /// A core skill has three or more dependants, or is marked core by its author.
  bool isCore(String id) => node(id).core || dependantsOf(id).length >= 3;

  /// Problems an author must fix: skills nothing uses and that use nothing, and skills without an item in
  /// at least two representations (a skill with a single way of being explained cannot be re-taught).
  List<String> report() {
    final List<String> out = <String>[];
    for (final SkillNode s in catalog.skills.values) {
      if (s.prerequisites.isEmpty && dependantsOf(s.id).isEmpty && catalog.skills.length > 1) {
        out.add('${s.id} is not connected to any other skill');
      }
      final Set<Representation> reps = <Representation>{
        for (final ItemMeta i in catalog.itemsFor(s.id)) i.representation,
      };
      if (catalog.itemsFor(s.id).isEmpty) {
        out.add('${s.id} has no item');
      } else if (reps.length < 2) {
        out.add('${s.id} has items in only one representation');
      }
    }
    return out;
  }
}
