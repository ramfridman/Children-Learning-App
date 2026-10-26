import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/params.dart';
import 'package:nitznutz/engine/types.dart';

/// A small skill graph for the engine tests:
///
///     A -> B -> C
///     A -> D
///
/// Every skill has two three-option items in different representations, one open "reverse" check, and two
/// probe items. The wrong answers of item `X1` carry the tag `M-X`, which traces back to the skill's first prerequisite.
Catalog smallCatalog({bool traceToRoot = true}) {
  const Map<String, List<String>> prerequisites = <String, List<String>>{
    'A': <String>[],
    'B': <String>['A'],
    'C': <String>['B'],
    'D': <String>['A'],
  };
  final List<SkillNode> skills = <SkillNode>[];
  final List<ItemMeta> items = <ItemMeta>[];
  final List<TagInfo> tags = <TagInfo>[];
  for (final MapEntry<String, List<String>> e in prerequisites.entries) {
    final String id = e.key;
    skills.add(
      SkillNode(
        id: 'SK-$id-01',
        prerequisites: <String, double>{for (final String p in e.value) 'SK-$p-01': 1.0},
        representations: <Representation>{
          Representation.concrete,
          Representation.pictorial,
          Representation.symbolic,
        },
        tags: <String>{'M-$id'},
      ),
    );
    final Map<String, double> sk = <String, double>{'SK-$id-01': 1.0};
    items.addAll(<ItemMeta>[
      ItemMeta(
        id: '$id.1',
        skills: sk,
        representation: Representation.concrete,
        variantGroup: '$id-g1',
        difficulty: 0.3,
        optionCount: 3,
        tags: <String>{'M-$id'},
      ),
      ItemMeta(
        id: '$id.2',
        skills: sk,
        representation: Representation.pictorial,
        variantGroup: '$id-g2',
        difficulty: 0.5,
        optionCount: 3,
      ),
      ItemMeta(
        id: '$id.3',
        skills: sk,
        representation: Representation.symbolic,
        checkType: CheckType.reverse,
        variantGroup: '$id-g3',
        difficulty: 0.7,
      ),
      ItemMeta(
        id: '$id.p1',
        skills: sk,
        purpose: Purpose.probe,
        representation: Representation.concrete,
        variantGroup: '$id-p',
        difficulty: 0.3,
        optionCount: 3,
        tags: <String>{'M-$id'},
      ),
      ItemMeta(
        id: '$id.p2',
        skills: sk,
        purpose: Purpose.probe,
        representation: Representation.pictorial,
        variantGroup: '$id-p',
        difficulty: 0.3,
        optionCount: 3,
      ),
    ]);
    tags.add(
      TagInfo(
        id: 'M-$id',
        skills: e.value.isEmpty
            ? <String>['SK-$id-01']
            : <String>[traceToRoot ? 'SK-${e.value.first}-01' : 'SK-$id-01'],
      ),
    );
  }
  return Catalog(skills: skills, items: items, tags: tags);
}

final DateTime day0 = DateTime.utc(2026, 11, 1, 9);

/// A helper that writes answers into an engine with a running clock.
class Story {
  Story(this.engine, {DateTime? start}) : at = start ?? day0;

  final Engine engine;
  DateTime at;
  int _id = 0;

  void answer(String item, Result result, {int hint = 0, String tag = '', int? session}) {
    engine.apply(
      AttemptEvent(
        id: ++_id,
        at: at,
        activityId: item,
        result: result,
        hintLevel: hint,
        tag: tag,
        sessionId: session,
      ),
    );
    at = at.add(const Duration(seconds: 40));
  }

  void right(String item, {int hint = 0, int? session}) =>
      answer(item, Result.correct, hint: hint, session: session);

  void wrong(String item, {String tag = '', int hint = 0, int? session}) =>
      answer(item, Result.incorrect, tag: tag, hint: hint, session: session);

  void days(int n) => at = at.add(Duration(days: n));
}

/// A text summary of everything in a state, to compare two replays.
String fingerprint(Engine e) {
  final StringBuffer b = StringBuffer();
  for (final String id in (e.state.skills.keys.toList()..sort())) {
    final s = e.state.skills[id]!;
    b.writeln(
      '$id p=${s.p.toStringAsFixed(6)} n=${s.n} ok=${s.nCorrect} succ=${s.successes} fresh=${s.freshAt} dur=${s.durableAt} rev=${s.needsRevisit} mem=${s.memory?.stability.toStringAsFixed(4)}',
    );
  }
  for (final String t in (e.state.tags.keys.toList()..sort())) {
    final s = e.state.tags[t]!;
    b.writeln('$t ${s.score.toStringAsFixed(6)} ${s.status.name} ${s.items.length} ${s.cleanRuns}');
  }
  for (final g in e.state.gaps) {
    b.writeln('gap ${g.origin}->${g.skill} ${g.probes} ${g.via} ${g.repaired}');
  }
  b.writeln('search ${e.state.search?.origin} ${e.state.search?.probes}');
  return b.toString();
}

Engine engineOf(Catalog c, {EngineParams params = const EngineParams()}) =>
    Engine(catalog: c, params: params);
