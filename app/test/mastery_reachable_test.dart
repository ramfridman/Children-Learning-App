import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/graph.dart';
import 'package:nitznutz/engine/params.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

/// Audit finding F2 (docs/knowledge/m9-audit.md, board B-15): can fresh mastery be reached on every skill of the
/// starter pack at all? An invented child answers every activity of a skill right, with no hint, once a day for
/// [_days] days, through the real engine (`Engine.apply` and its `_checkFresh`). If even that child never gets the
/// leafy plant, the content cannot give the evidence the mastery rule asks for (§4.1: an understanding check,
/// two of them and two representations for a core skill).
///
/// The target is every skill reachable and `graph.report()` empty on the real pack. Until the content of B-15 is
/// in, those two tests FAIL; they are skipped in a normal run so that the suite stays green. Run them with
///
///   flutter test --no-pub --dart-define=QA_OPEN=true test/mastery_reachable_test.dart
///
/// When the content is fixed, remove `skip: _open` (they then guard every build).
const bool _open = !bool.fromEnvironment('QA_OPEN');

/// Days the invented child plays; the rule needs 2, so 4 leaves room.
const int _days = 4;

/// Why a skill never reached fresh mastery, in the order `_checkFresh` tests the conditions.
String? _whyNotFresh(Engine engine, String id) {
  final SkillState? s = engine.state.skills[id];
  if (s == null || !s.started) return 'no playable activity';
  if (s.freshAt != null) return null;
  const EngineParams p = EngineParams();
  final bool core = engine.graph.isCore(id);
  final SkillNode node = engine.graph.node(id);
  final List<String> why = <String>[];
  if (s.p < p.masteryBar) why.add('estimate ${s.p.toStringAsFixed(2)} < ${p.masteryBar}');
  final int needSucc = node.needSuccesses ?? (core ? p.freshSuccessesCore : p.freshSuccesses);
  if (s.successes < needSucc) why.add('successes ${s.successes} < $needSucc');
  final int needDays = node.needDays ?? p.freshDays;
  if (s.successDays.length < needDays) why.add('days ${s.successDays.length} < $needDays');
  final int needReps =
      node.needRepresentations ?? (core ? p.freshRepresentationsCore : p.freshRepresentations);
  if (s.representationsPassed.length < needReps) {
    why.add(
      'representations ${s.representationsPassed.map((Representation r) => r.name).toList()} < $needReps',
    );
  }
  final int needChecks = node.needChecks ?? (core ? p.freshChecksCore : p.freshChecks);
  if (s.checksPassed.length < needChecks) {
    why.add('understanding checks ${s.checksPassed.map((CheckType c) => c.name).toList()} < $needChecks');
  }
  return why.join('; ');
}

/// A fresh engine per skill, with the invented child who is always right.
Engine _perfectChildOn(Catalog catalog, String skillId) {
  final Engine engine = Engine(catalog: catalog);
  final List<ItemMeta> items = catalog.itemsFor(skillId)
    ..sort((ItemMeta a, ItemMeta b) => a.id.compareTo(b.id));
  final DateTime start = DateTime.utc(2026, 11, 2, 9);
  int n = 0;
  for (int day = 0; day < _days; day++) {
    for (final ItemMeta item in items) {
      engine.apply(
        AttemptEvent(
          id: ++n,
          at: start.add(Duration(days: day, minutes: n)),
          activityId: item.id,
          result: Result.correct,
          sessionId: day + 1,
        ),
      );
    }
  }
  return engine;
}

Map<String, String> _unreachable(Catalog catalog) {
  final Map<String, String> out = <String, String>{};
  final List<String> ids = catalog.skills.keys.toList()..sort();
  for (final String id in ids) {
    final String? why = _whyNotFresh(_perfectChildOn(catalog, id), id);
    if (why != null) out[id] = why;
  }
  return out;
}

void main() {
  late Catalog catalog;

  setUpAll(() async {
    // The real source folder, built and verified with a throw-away key (as pack_builder_test does).
    final PackKey key = await newTestKey();
    final BuiltPack built = await buildPack(Directory('../content/starter'), key);
    final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
    catalog = engineCatalog(PackContent.fromPack(pack));
  });

  test('the harness is sound: with a check and two representations the perfect child reaches fresh mastery', () {
    // A synthetic skill with exactly what the rule asks of a core skill, so a failure on the real pack is the
    // content and not this test.
    final Catalog ok = Catalog(
      skills: const <SkillNode>[SkillNode(id: 'X-A-01', core: true)],
      items: <ItemMeta>[
        for (int i = 0; i < 4; i++)
          ItemMeta(id: 'x.p$i', skills: const <String, double>{'X-A-01': 1}, optionCount: 3),
        const ItemMeta(
          id: 'x.give',
          skills: <String, double>{'X-A-01': 1},
          checkType: CheckType.reverse,
          representation: Representation.pictorial,
        ),
        const ItemMeta(
          id: 'x.predict',
          skills: <String, double>{'X-A-01': 1},
          checkType: CheckType.predict,
          optionCount: 3,
        ),
      ],
    );
    expect(_whyNotFresh(_perfectChildOn(ok, 'X-A-01'), 'X-A-01'), isNull);
    // And the same skill without its checks does not.
    final Catalog weak = Catalog(
      skills: ok.skills.values,
      items: ok.items.values.where((ItemMeta i) => i.checkType == CheckType.practice),
    );
    expect(_whyNotFresh(_perfectChildOn(weak, 'X-A-01'), 'X-A-01'), contains('understanding checks'));
  });

  test('the measurement runs on the real pack (prints the skills that cannot reach fresh mastery)', () {
    final Map<String, String> bad = _unreachable(catalog);
    final SkillGraph graph = SkillGraph(catalog);
    int noCheck = 0, oneRep = 0, core = 0;
    for (final MapEntry<String, String> e in bad.entries) {
      if (e.value.contains('understanding checks')) noCheck++;
      if (e.value.contains('representations')) oneRep++;
      if (graph.isCore(e.key)) core++;
    }
    // ignore: avoid_print
    print(
      'F2: ${bad.length} of ${catalog.skills.length} skills cannot reach fresh mastery '
      '($noCheck lack an understanding check, $oneRep lack a representation, $core are core); '
      'graph.report() has ${graph.report().length} lines',
    );
    for (final MapEntry<String, String> e in bad.entries) {
      // ignore: avoid_print
      print('  ${e.key}${graph.isCore(e.key) ? ' (core)' : ''}: ${e.value}');
    }
    expect(catalog.skills, isNotEmpty);
  });

  test('every skill of the starter pack can reach fresh mastery (F2, B-15)', () {
    final Map<String, String> bad = _unreachable(catalog);
    expect(
      bad,
      isEmpty,
      reason:
          '${bad.length} skills cannot reach fresh mastery even with every answer right:\n'
          '${bad.entries.map((MapEntry<String, String> e) => '${e.key}: ${e.value}').join('\n')}',
    );
  }, skip: _open);

  test('graph.report() is empty on the starter pack (every skill in at least two representations)', () {
    final List<String> report = SkillGraph(catalog).report();
    expect(report, isEmpty, reason: report.join('\n'));
  }, skip: _open);
}
