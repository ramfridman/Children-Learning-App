// SEC-12: everything the app can put in an event fits what sync-push takes (`testvectors/wire-patterns.json`, which the
// Deno tests hold equal to the gateway). The fake server of the sync tests refuses what the real one would; this file
// checks the values that come from the pack, over the whole starter pack, and from the app's own lists.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/reward_rules.dart';
import 'package:nitznutz/sync/sync_engine.dart';
import 'package:nitznutz/world/world_state.dart';

import 'support/starter.dart';

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;

void main() {
  late PackContent content;
  final Map<String, Object?> wire =
      jsonDecode(File('../testvectors/wire-patterns.json').readAsStringSync()) as Map<String, Object?>;
  final Map<String, Object?> data = _m(wire['data_fields']);

  setUpAll(() async {
    content = await loadStarter();
  });

  Map<String, Object?> field(String key) => _m(data[key]);

  /// True if sync-push takes [value] as the data key [key].
  bool fits(String key, Object? value) {
    final Map<String, Object?> f = field(key);
    return switch (f['t']) {
      'string' =>
        value is String &&
            value.length <= (f['max']! as int) &&
            RegExp(f['pattern']! as String).hasMatch(value),
      'int' => value is int && value >= (f['min']! as int) && value <= (f['max']! as int),
      'enum' => (f['values']! as List<Object?>).contains(value),
      _ => false,
    };
  }

  test('every pack field an answer, a visit or a reward carries fits, for the whole starter pack', () {
    final List<String> bad = <String>[];
    void check(String key, Object? value) {
      if (!fits(key, value)) bad.add('$key = $value');
    }

    check('pack_id', content.packId);
    check('pack_version', content.packVersion);
    for (final Lesson l in content.lessons.values) {
      check('lesson_id', l.id);
      check('plan', 'lesson:${l.id}');
      check('key', Awards.sticker(l.id, 9999));
    }
    for (final Activity a in content.activities.values) {
      check('activity_id', a.id);
      check('activity_revision', a.revision);
      check('template', a.template);
      check('template_version', a.templateVersion);
      check('skill_id', a.skillId);
    }
    final Engine engine = Engine(catalog: engineCatalog(content));
    final WorldView world = WorldView(
      engine: engine,
      now: DateTime.utc(2026, 11, 20),
      lands: const <TrophyLand, List<WorldObject>>{},
    );
    int missions = 0;
    for (final String s in content.skills.keys) {
      check('key', Awards.star(s));
      check('plan', 'mission:${s.toLowerCase()}');
      final Lesson? mission = world.missionFor(s);
      if (mission != null) {
        missions++;
        check('lesson_id', mission.id);
      }
    }
    for (final String t in content.tags.keys) {
      check('misconception_tag', t);
    }
    expect(missions, greaterThan(0), reason: 'revisit missions were made');
    expect(bad, isEmpty, reason: 'sync-push would refuse these');
  });

  test('the pack schema bounds every id an answer carries by the server\'s own length', () {
    int maxOf(SField f) => (f.schema as SString).maxLength;
    final Map<String, SField> lesson = lessonSchema.fields;
    final Map<String, SField> manifest = manifestSchema.fields;
    final Map<String, SField> entries = (manifest['entries']!.schema as SObject).fields;
    int itemMax(SField f) => ((f.schema as SArray).items as SString).maxLength;
    int max(String key) => field(key)['max']! as int;
    expect(maxOf(lesson['id']!), lessThanOrEqualTo(max('lesson_id')));
    expect(itemMax(entries['lessons']!), lessThanOrEqualTo(max('lesson_id')));
    expect(itemMax(entries['activities']!), lessThanOrEqualTo(max('activity_id')));
    expect(itemMax(entries['skills']!), lessThanOrEqualTo(max('skill_id')));
    expect(itemMax(entries['misconceptions']!), lessThanOrEqualTo(max('misconception_tag')));
    expect(maxOf(manifest['id']!), lessThanOrEqualTo(max('pack_id')));
    expect(maxOf(manifest['version']!), lessThanOrEqualTo(max('pack_version')));
  });

  test('the app\'s own lists are among the values the server takes', () {
    expect(
      field('kind')['values'],
      containsAll(<String>[for (final AwardKind k in AwardKind.values) k.name]),
    );
    expect(field('result')['values'], containsAll(<String>[for (final Result r in Result.values) r.name]));
    expect(field('input')['values'], containsAll(<String>['tap', 'voice']));
    expect(field('end_reason')['values'], containsAll(<String>['', 'finished', 'home', 'limit']));
    final List<String> keys = <String>[
      for (final TrophyLand land in TrophyLand.values)
        for (final TrophyTier tier in TrophyTier.values) Awards.trophy(land, tier),
      for (final MedalDef m in medalDefs) Awards.medal(m.id),
      for (final int n in decorationSteps) Awards.decoration(n),
    ];
    expect(<String>[
      for (final String k in keys)
        if (!fits('key', k)) k,
    ], isEmpty);
  });

  test('the sync boundary uses the server\'s own limits', () {
    expect(SyncEngine.lessonIdPattern, field('lesson_id')['pattern']);
    expect(SyncEngine.maxDurationMs, field('duration_ms')['max']);
    expect(SyncEngine.wireLessonId('mission-NUM-A-03'), 'mission-num-a-03');
    expect(SyncEngine.wireLessonId('butterflies'), 'butterflies');
    expect(SyncEngine.wireLessonId('l' * 41), '');
  });
}
