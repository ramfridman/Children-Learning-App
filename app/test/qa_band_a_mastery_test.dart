// QA of Languages Band A (2026-11-07): can fresh mastery be reached on every skill of each course pack, by a child who answers every
// item of a skill right, with no hint, once a day for four days, through the real engine? (the model is mastery_reachable_test.dart)
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/gates.dart';
import 'package:nitznutz/engine/graph.dart';
import 'package:nitznutz/engine/params.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/app/language_providers.dart' show languageCourseOf;
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import '../tool/pack_builder_lib.dart';
import 'support/course_history.dart';
import 'support/pack_fixtures.dart';

String? _why(Engine engine, String id) {
  final SkillState? s = engine.state.skills[id];
  // A trace node (rule E-1) is met once every stroke is practised, and is never fresh.
  if (engine.graph.node(id).writing == WritingRule.practised) {
    return engine.isMet(id)
        ? null
        : 'a trace node not met: practised ${s?.practisedGroups}, of ${engine.catalog.practiceGroupsOf(id)}';
  }
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
    why.add('checks ${s.checksPassed.map((CheckType c) => c.name).toList()} < $needChecks');
  }
  if (node.setCoverage) {
    final Set<String> missing = engine.catalog.variantGroupsOf(id).difference(s.successGroups);
    if (missing.isNotEmpty) why.add('set coverage: groups never answered right unhinted: $missing');
  }
  return why.join('; ');
}

Engine _child(Catalog catalog, String skillId) {
  final Engine engine = Engine(catalog: catalog);
  final List<ItemMeta> items = catalog.itemsFor(skillId)
    ..sort((ItemMeta a, ItemMeta b) => a.id.compareTo(b.id));
  final DateTime start = DateTime.utc(2026, 11, 2, 9);
  int n = 0;
  for (int day = 0; day < 4; day++) {
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

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());
  for (final String course in Course.languages) {
    test('$course: every Band A skill can reach fresh mastery (a perfect child, 4 days)', () async {
      final BuiltPack built = await buildPack(languageSource(course, '../content/languages'), key);
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      final Catalog catalog = engineCatalog(PackContent.fromPack(pack));
      final Map<String, String> bad = <String, String>{};
      final List<String> ids = catalog.skills.keys.toList()..sort();
      for (final String id in ids) {
        final SkillGraph g = SkillGraph(catalog);
        final String? why = _why(_child(catalog, id), id);
        // ignore: avoid_print
        print('QA $course $id core=${g.isCore(id)} items=${catalog.itemsFor(id).length} ${why ?? 'FRESH'}');
        if (why != null) bad[id] = why;
      }
      expect(
        bad,
        isEmpty,
        reason: bad.entries.map((MapEntry<String, String> e) => '${e.key}: ${e.value}').join('\n'),
      );
    });
  }

  test('rus: a perfect child opens the Russian sounds gate (A-12 and three themes mastered) and the skills it holds', () async {
    final BuiltPack built = await buildPack(languageSource('rus', '../content/languages'), key);
    final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
    final PackContent content = PackContent.fromPack(pack);
    final Catalog catalog = engineCatalog(content);
    final Engine engine = Engine(catalog: catalog);
    final DateTime start = DateTime.utc(2026, 11, 2, 9);
    int n = 0;
    for (int day = 0; day < 4; day++) {
      for (final ItemMeta item
          in catalog.items.values.toList()..sort((ItemMeta a, ItemMeta b) => a.id.compareTo(b.id))) {
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
    final Map<String, MasteryLevel> mastery = masteryLevels(engine);
    for (final CourseGate g in courseGates(content)) {
      final GateResult r = gateResult(
        g,
        GateInput(mastery: mastery, ageBand: 0, presentationBand: 0, route: 'new'),
      );
      expect(
        r.open,
        isTrue,
        reason:
            '${g.id} stays closed for a child who answered everything right four days running; missing ${r.missing}',
      );
    }
  });

  test('heb: HEB-A-14 (the pre-writing trace node) is met once its strokes are traced (rule E-1)', () async {
    final BuiltPack built = await buildPack(languageSource('heb', '../content/languages'), key);
    final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
    final Catalog catalog = engineCatalog(PackContent.fromPack(pack));
    final Engine engine = _child(catalog, 'HEB-A-14');
    expect(
      catalog.skills['HEB-A-14']!.writing,
      isNotNull,
      reason: 'HEB-A-14 does not declare writing: practised',
    );
    expect(engine.isMet('HEB-A-14'), isTrue);
  });

  // The flow of the course home (docs/languages/band-a-build.md section 7.4): a child who goes where the course stop sends them, three visits
  // a day, answering everything right without a hint. Lessons, then the check visits on later days, a revisit of a fresh skill when one
  // is due. Every skill must reach fresh mastery (a trace node, met), or the content or the visit leaves a skill that cannot.
  for (final String course in Course.languages) {
    test(
      '$course: a child who follows the course stop, every answer right, reaches fresh mastery of every skill',
      () async {
        final BuiltPack built = await buildPack(languageSource(course, '../content/languages'), key);
        final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
        final PackContent content = PackContent.fromPack(pack);
        final LanguageCourse home = languageCourseOf(
          content,
          const <Attempt>[],
          const LanguageSwitches(on: true),
          0,
        );
        final Engine engine = home.engine;
        final List<Attempt> attempts = <Attempt>[];
        final List<Session> sessions = <Session>[];
        final Map<String, int> finished = <String, int>{};
        final DateTime start = DateTime.utc(2026, 11, 2);
        final List<String> skills = <String>[
          for (final String id in engine.catalog.skills.keys)
            if (!engine.catalog.isRollUp(id)) id,
        ]..sort();
        List<String> notDone() => <String>[
          for (final String id in skills)
            if (_why(engine, id) != null) id,
        ];
        int id = 0;
        int visits = 0;
        int checkVisits = 0;
        int day = 0;
        final Map<String, int> kinds = <String, int>{};
        for (; day < 200 && notDone().isNotEmpty; day++) {
          for (int k = 0; k < 3; k++) {
            final DateTime now = start.add(Duration(days: day, hours: 9 + k));
            final TodaysAdventure stop = courseStopFor(
              course: home,
              attempts: attempts,
              sessions: sessions,
              finished: finished,
              now: now,
              band: 0,
            );
            final Lesson? lesson = switch (stop.kind) {
              AdventureKind.lesson || AdventureKind.replay => content.lessons[stop.lessonId],
              AdventureKind.revisit =>
                stop.reason == AdventureReason.checkVisit
                    ? courseCheckVisit(home, stop.skillId!, band: 0)
                    : courseMission(home, stop.skillId!),
              AdventureKind.none => null,
            };
            if (lesson == null) continue;
            visits++;
            kinds[stop.reason.name] = (kinds[stop.reason.name] ?? 0) + 1;
            if (stop.reason == AdventureReason.checkVisit) checkVisits++;
            final bool mission = lesson.id.startsWith('mission-');
            final int session = sessions.length + 1;
            sessions.add(
              sessionRow(session, mission ? 'mission:${lesson.id}' : 'lesson:${lesson.id}', at: now),
            );
            final List<String> items = mission
                ? lesson.itemIds
                : <String>[
                    for (final Activity a in content.itemsFor(lesson, route: course == 'rus' ? 'new' : null))
                      if (!a.teachScreen) a.id,
                  ];
            for (final String item in items) {
              if (content.activities[item]?.unscored ?? true) continue;
              final Attempt row = attemptRow(
                content,
                item,
                at: now.add(Duration(minutes: ++id % 50)),
                lessonId: lesson.id,
                id: id,
                sessionId: session,
              );
              attempts.add(row);
              engine.apply(eventOf(row));
            }
            if (!mission) finished[lesson.id] = (finished[lesson.id] ?? 0) + 1;
          }
        }
        final List<String> bad = notDone();
        // ignore: avoid_print
        print(
          'QA-FLOW $course: after $day days and $visits visits ($checkVisits check visits; $kinds) '
          '${skills.length - bad.length} of ${skills.length} skills are fresh (or met)',
        );
        expect(bad, isEmpty, reason: bad.map((String s) => '$s: ${_why(engine, s)}').join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 8)),
    );
  }
}
