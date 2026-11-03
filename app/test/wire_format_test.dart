// SEC-12: everything the app can put in an event fits what sync-push takes (`testvectors/wire-patterns.json`, which the
// Deno tests hold equal to the gateway). The fake server of the sync tests refuses what the real one would; this file
// checks the values that come from the pack, over the whole starter pack, and from the app's own lists.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/reward_rules.dart';
import 'package:nitznutz/sync/sync_engine.dart';
import 'package:nitznutz/world/world_state.dart';

import 'support/sample_pack.dart';
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

  test(
    'everything a language course\'s pack carries fits too: dotted skill ids, language tag ids, its pack id',
    () {
      for (final String course in Course.languages) {
        final PackContent lang = PackContent.fromPack(SamplePack.language(course).verified());
        final List<String> bad = <String>[];
        void check(String key, Object? value) {
          if (!fits(key, value)) bad.add('$key = $value');
        }

        check('pack_id', lang.packId);
        check('course', lang.course);
        for (final Activity a in lang.activities.values) {
          check('skill_id', a.skillId);
        }
        for (final String t in lang.tags.keys) {
          check('misconception_tag', t);
        }
        for (final String s in <String>[
          '${course.toUpperCase()}-B-19.G1',
          '${course.toUpperCase()}-B-14.S10',
        ]) {
          check('skill_id', s);
          check('key', Awards.star(s));
        }
        expect(bad, isEmpty, reason: '$course: sync-push would refuse these');
      }
      expect(fits('course', 'fra'), isFalse);
      expect(fits('skill_id', 'ENG-B-19.g1'), isFalse);
      expect(fits('misconception_tag', 'eng.ph'), isFalse);
    },
  );

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

  // R2: the number that resets the markers of refused rows is a number of this file. The file is the format; when it changes,
  // the rows the server refused under the old one deserve another try, so `SyncEngine.currentWireFormat` goes up with it and
  // the digest of the new file is written here. The engine number of the events is not touched.
  test('the wire format number follows testvectors/wire-patterns.json: change the file, raise the number', () {
    const Map<int, String> pinned = <int, String>{
      1: '7e97bab38490a13af04d450cbc10057dbe948a10abe9a577dd3ba2232df16cf1',
      2: '13b732637eb5d446281f7acb58239871733c8341d7ba9665a9fa3cda5ac884aa',
    };
    final String digest = sha256.convert(utf8.encode(jsonEncode(wire))).toString();
    expect(
      pinned[SyncEngine.currentWireFormat],
      digest,
      reason:
          'testvectors/wire-patterns.json changed (digest $digest): raise SyncEngine.currentWireFormat and add '
          'the digest under the new number',
    );
    expect(pinned.keys.reduce((int a, int b) => a > b ? a : b), SyncEngine.currentWireFormat);
  });
}
