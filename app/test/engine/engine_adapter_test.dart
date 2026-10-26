import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/graph.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import '../support/starter.dart';

void main() {
  late PackContent content;
  late Catalog catalog;

  setUpAll(() async {
    content = await loadStarter();
    catalog = engineCatalog(content);
  });

  test('the starter pack makes a skill graph the engine accepts', () {
    final SkillGraph g = SkillGraph(catalog);
    expect(
      catalog.skills.keys,
      containsAll(<String>['NUM-A-01', 'NUM-A-02', 'NUM-A-03', 'NUM-A-04', 'COL-A-02']),
    );
    expect(g.depth('NUM-A-04'), 2);
    expect(g.ancestors('NUM-A-04'), <String>{'NUM-A-03', 'NUM-A-01'});
    expect(g.isCore('NUM-A-01'), isTrue);
    expect(catalog.skills['NUM-A-01']!.core, isTrue);
  });

  test('the items carry what the engine needs', () {
    final ItemMeta count5 = catalog.items['count.butterflies.5']!;
    expect(count5.optionCount, 3);
    expect(count5.tags, <String>{'M-CNT-SKIP', 'M-CNT-DOUBLE'});
    expect(count5.skills.keys, <String>['NUM-A-03', 'NUM-A-04']);
    expect(count5.purpose, Purpose.learn);
    final ItemMeta give = catalog.items['give.butterflies.4']!;
    expect(give.optionCount, 0);
    expect(give.checkType, CheckType.reverse);
    expect(give.contradicts, 'M-CNT-CARD');
    expect(give.tags, <String>{'M-CNT-CARD'});
    expect(catalog.tags['M-CNT-DOUBLE']!.skills, <String>['NUM-A-03']);
  });

  test('the content authors are told what is missing: the starter has no probe items yet', () {
    // A gap search needs probe items (open ones are best); the starter lesson has none, so it cannot be probed.
    expect(catalog.items.values.where((ItemMeta i) => i.purpose == Purpose.probe), isEmpty);
    expect(SkillGraph(catalog).report(), isNotEmpty);
  });

  test('the answers of a child, read back from the database, become the engine state', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    int n = 0;
    Future<void> record(String activity, String result, {String tag = '', int hint = 0}) => db.recordAttempt(
      AttemptsCompanion.insert(
        at: DateTime.utc(2026, 11, 1, 9, 0, n++),
        profileId: 'p1',
        packId: 'starter',
        packVersion: '0.2.0',
        activityId: activity,
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: 'NUM-A-03',
        result: result,
        attemptNo: 1,
        hintLevel: hint,
        misconceptionTag: Value(tag),
      ),
    );
    await record('count.butterflies.3', 'incorrect', tag: 'M-CNT-DOUBLE');
    await record('count.butterflies.4', 'incorrect', tag: 'M-CNT-DOUBLE');
    await record('count.butterflies.5', 'correct', hint: 2);
    final Engine e = Engine(catalog: catalog)..replay((await db.attemptsOf('p1')).map(eventOf));
    expect(e.state.tags['M-CNT-DOUBLE']!.status, TagStatus.active);
    expect(e.state.skills['NUM-A-03']!.n, 3);
    final String text = engineSummary(e, DateTime.utc(2026, 11, 2));
    expect(text, contains('NUM-A-03: learning'));
    expect(text, contains('misconception M-CNT-DOUBLE: active'));
    expect(text, contains('NUM-A-01: ready'));
    expect(text, contains('NUM-A-04: learning'));
    expect(text, contains('NUM-A-02: notStarted'));
  });
}
