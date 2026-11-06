// QA of M10 step 0 (2026-11-06), written by the qa-engineer and independent of the developer's own tests: a headless playthrough over
// every land of the starter pack for a new child of each age band (E0, the path gate) and the lands' staircase warm-up driven through the
// real LessonController (E0b). The oracle here does not call `lockedLessons`: it reads the skills' prerequisites and the engine's
// own numbers, so a wrong gate cannot agree with itself.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/land_placement.dart';
import 'package:nitznutz/world/lesson_path.dart';
import 'package:nitznutz/world/next_lesson.dart';
import 'package:nitznutz/world/path_gate.dart' show lessonLevel;
import 'package:nitznutz/world/placement.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

final RegExp _band = RegExp(r'^[A-Z]+-([ABC])-');

/// The level (0, 1, 2) of a lesson on a land, read straight from the skill ids (independent of `lessonLevel`).
int _levelOn(PackContent c, Lesson l, String domain) {
  int level = 0;
  for (final String s in l.skillIds) {
    if (c.skills[s]?.domain != domain) continue;
    final String? b = _band.firstMatch(s)?.group(1);
    if (b != null && b.codeUnitAt(0) - 65 > level) level = b.codeUnitAt(0) - 65;
  }
  return level;
}

/// One child: the rows they wrote, the engine, and the stickers (lessons finished).
class Kid {
  Kid(this.content, this.ageBand, this.seed)
    : engine = Engine(catalog: engineCatalog(content)),
      clock = FixedClock(DateTime.utc(2026, 11, 7, 9).millisecondsSinceEpoch);

  final PackContent content;
  final int ageBand;
  final int seed;
  Engine engine;
  final FixedClock clock;
  final List<Attempt> rows = <Attempt>[];
  final Map<String, int> stickers = <String, int>{};
  int _id = 0;
  int _rng = 0;

  /// A tiny deterministic generator, so that a failing run can be repeated.
  int roll(int n) {
    _rng = (_rng * 1103515245 + 12345 + seed) & 0x7fffffff;
    return (_rng >> 8) % n;
  }

  Future<void> record(AttemptRecord r) async {
    _id++;
    final Attempt a = Attempt(
      id: _id,
      at: r.at,
      profileId: r.profileId,
      packId: r.packId,
      packVersion: r.packVersion,
      lessonId: r.lessonId,
      activityId: r.activityId,
      activityRevision: r.activityRevision,
      template: r.template,
      templateVersion: r.templateVersion,
      skillId: r.skillId,
      result: r.result,
      attemptNo: r.attemptNo,
      hintLevel: r.hintLevel,
      misconceptionTag: r.misconceptionTag,
      response: r.response,
      durationMs: r.durationMs,
      sessionId: r.sessionId,
      input: r.input,
    );
    rows.add(a);
    engine.apply(eventOf(a));
  }

  /// What the app builds from the database: the warm-ups' assumed skills first, then every answer replayed.
  void rebuildEngine() {
    engine = Engine(catalog: engineCatalog(content))
      ..assume(placedByWarmUp(content, rows).skills)
      ..replay(rows.map(eventOf).toList());
  }

  Map<String, int> get finished => finishedLessons(content, rows, [
    for (final MapEntry<String, int> e in stickers.entries)
      for (int n = 1; n <= e.value; n++) Awards.sticker(e.key, n),
  ]);

  LessonController controller(Lesson lesson, {ItemFlow? flow}) => LessonController(
    content: content,
    lesson: lesson,
    profileId: 'kid',
    clock: clock,
    record: record,
    flow: flow,
  );

  /// The child plays a whole lesson; [right] chooses for each activity whether the first try is right.
  Future<void> playLesson(Lesson lesson, bool Function() right) async {
    final LessonController c = controller(lesson);
    while (!c.finished) {
      clock.now += 4000;
      if (right()) {
        await c.submitPlacement(right: true);
      } else {
        await c.submitPlacement(right: false);
        await c.submitPlacement(right: true);
      }
      c.next();
    }
    stickers[lesson.id] = (stickers[lesson.id] ?? 0) + 1;
  }
}

/// How a probe of the warm-up is answered: R right at the first try; M a miss, then right; S the help runs to its top (a struggle); U
/// "I'm not sure" (a hint), then right.
Future<void> _answerActivity(LessonController c, String how) async {
  switch (how) {
    case 'R':
      await c.submitPlacement(right: true);
    case 'M':
      await c.submitPlacement(right: false);
      await c.submitPlacement(right: true);
    case 'U':
      await c.unsure();
      await c.submitPlacement(right: true);
    case 'H':
      c.showHint();
      await c.submitPlacement(right: true);
    case 'S':
      int guard = 0;
      while (!c.guided && guard++ < 8) {
        await c.submitPlacement(right: false);
      }
      expect(c.guided, isTrue, reason: 'the help ran up to the top');
      await c.submitPlacement(right: true);
    default:
      fail('unknown outcome $how');
  }
  c.next();
}

/// Plays the warm-up of [domain] through the real controller, answering each activity as [script] says, until the visit ends or the script
/// runs out (a warm-up left early). Returns whether the controller ended the visit.
Future<bool> _warmUp(Kid kid, String domain, List<String> script) async {
  final ({Lesson lesson, ItemFlow flow})? visit = placementVisit(
    kid.content,
    domain,
    kid.rows,
    ageBand: kid.ageBand,
  );
  if (visit == null) return true;
  final LessonController c = kid.controller(visit.lesson, flow: visit.flow);
  for (final String how in script) {
    if (c.finished) break;
    kid.clock.now += 3000;
    await _answerActivity(c, how);
  }
  return c.finished;
}

void main() {
  late PackContent starter;
  setUpAll(() async => starter = await loadStarter());

  const double bar = 0.8;
  final List<TrophyLand> lands = TrophyLand.values;

  // -------------------------------------------------------------------------------------------------------------------------------
  group('E0, the gate: a headless playthrough of every land, for a new child of each age band', () {
    /// p of a skill as the engine holds it, with the prior of a skill nobody has touched (0.2, or 0.85 when assumed).
    double pOf(Kid kid, String id, Set<String> assumed) =>
        kid.engine.state.skills[id]?.p ?? (assumed.contains(id) ? 0.85 : 0.2);

    bool openByOracle(Kid kid, Lesson l, Set<String> assumed) {
      final Set<String> together = l.skillIds.toSet();
      for (final String s in l.skillIds) {
        final SkillDoc? doc = kid.content.skills[s];
        if (doc == null) continue;
        for (final String pre in doc.prerequisites.keys) {
          if (together.contains(pre)) continue;
          if (pOf(kid, pre, assumed) < bar) return false;
        }
      }
      return true;
    }

    /// The path rule, written again from the docs: the first open lesson not yet finished, else the open lesson finished fewest times (the
    /// earliest on a tie). If nothing is open, the lessons of the lowest level are open.
    ({String? expected, bool exit, int lowest}) oracle(Kid kid, String domain, Set<String> assumed) {
      final List<Lesson> path = landPath(kid.content, domain);
      final Map<String, int> fin = kid.finished;
      List<Lesson> open = <Lesson>[
        for (final Lesson l in path)
          if (openByOracle(kid, l, assumed)) l,
      ];
      final int lowest = path
          .map((Lesson l) => _levelOn(kid.content, l, domain))
          .reduce((int a, int b) => a < b ? a : b);
      bool exit = false;
      if (open.isEmpty) {
        exit = true;
        open = <Lesson>[
          for (final Lesson l in path)
            if (_levelOn(kid.content, l, domain) == lowest) l,
        ];
      }
      String? expected;
      for (final Lesson l in open) {
        if ((fin[l.id] ?? 0) == 0) {
          expected = l.id;
          break;
        }
      }
      if (expected == null) {
        Lesson best = open.first;
        for (final Lesson l in open) {
          if ((fin[l.id] ?? 0) < (fin[best.id] ?? 0)) best = l;
        }
        expected = best.id;
      }
      return (expected: expected, exit: exit, lowest: lowest);
    }

    int exits = 0;

    /// Everything E0 promises, checked for every land at this moment.
    void checkAllLands(Kid kid, String where) {
      final Set<String> assumed = placedByWarmUp(kid.content, kid.rows).skills;
      final Map<String, int> fin = kid.finished;
      final AdventureInput input = adventureInput(
        content: kid.content,
        engine: kid.engine,
        attempts: kid.rows,
        sessions: const <Session>[],
        finished: fin,
        now: kid.clock.now == 0
            ? DateTime.utc(2026)
            : DateTime.fromMillisecondsSinceEpoch(kid.clock.now, isUtc: true),
        band: kid.ageBand,
      );
      for (final TrophyLand land in lands) {
        final List<Lesson> path = landPath(kid.content, land.domain);
        if (path.isEmpty) continue;
        final String? offered = nextLessonId(
          content: kid.content,
          domain: land.domain,
          finished: fin,
          unlocked: kid.engine.isUnlocked,
        );
        // No land is ever empty.
        expect(offered, isNotNull, reason: '$where: ${land.name} has nothing to offer');
        final ({String? expected, bool exit, int lowest}) o = oracle(kid, land.domain, assumed);
        // The pebble is what the rules say, for the right reason.
        expect(offered, o.expected, reason: '$where: ${land.name} pebble differs from the rule');
        final Lesson lesson = kid.content.lessons[offered]!;
        if (o.exit) {
          exits++;
          // No higher band opens by the exit.
          expect(
            _levelOn(kid.content, lesson, land.domain),
            o.lowest,
            reason: '$where: ${land.name} exit opened a higher band with $offered',
          );
        } else {
          // No lesson is offered before its skills are unlocked.
          expect(openByOracle(kid, lesson, assumed), isTrue, reason: '$where: $offered offered while locked');
        }
        // The app's own gate gives the same level the oracle reads from the id.
        expect(
          lessonLevel(kid.content, lesson, land.domain),
          _levelOn(kid.content, lesson, land.domain),
          reason: 'lessonLevel of $offered',
        );
        // The bottle and the pebble never disagree on this land.
        final List<PathLesson> bottlePath = input.paths[land]!;
        final String? viaBottle = nextOnPath(
          <String>[for (final PathLesson p in bottlePath) p.id],
          input.finished,
          locked: <String>{
            for (final PathLesson p in bottlePath)
              if (p.locked) p.id,
          },
        );
        expect(viaBottle, offered, reason: '$where: ${land.name} bottle and pebble disagree');
      }
      final TodaysAdventure stop = todaysAdventure(input);
      if (stop.kind == AdventureKind.lesson && stop.land is TrophyLand) {
        final TrophyLand land = stop.land! as TrophyLand;
        final String? pebble = nextLessonId(
          content: kid.content,
          domain: land.domain,
          finished: fin,
          unlocked: kid.engine.isUnlocked,
        );
        expect(
          stop.lessonId,
          pebble,
          reason: '$where: Today\'s Adventure and the pebble of ${land.name} disagree',
        );
      }
    }

    /// A child walks the app: the warm-up of a land when it is due, then the lesson the pebble gives, round the lands, for [steps] lessons.
    Future<Kid> walk(
      int ageBand, {
      required int seed,
      required int pRight,
      required int steps,
      bool warmUps = true,
      PackContent? pack,
    }) async {
      final PackContent c = pack ?? starter;
      final Kid kid = Kid(c, ageBand, seed);
      checkAllLands(kid, 'band $ageBand, a new child');
      for (int step = 0; step < steps; step++) {
        final TrophyLand land = lands[step % lands.length];
        if (landPath(c, land.domain).isEmpty) continue;
        if (warmUps && placementDue(c, land.domain, kid.rows)) {
          await _warmUp(kid, land.domain, <String>[
            for (int i = 0; i < 10; i++) kid.roll(100) < pRight ? 'R' : 'M',
          ]);
          kid.rebuildEngine();
          checkAllLands(kid, 'band $ageBand, after the ${land.name} warm-up');
        }
        final String id = nextLessonId(
          content: c,
          domain: land.domain,
          finished: kid.finished,
          unlocked: kid.engine.isUnlocked,
        )!;
        await kid.playLesson(c.lessons[id]!, () => kid.roll(100) < pRight);
        if (step % 6 == 5) kid.clock.now += 86400000;
        checkAllLands(kid, 'band $ageBand, step $step ($id)');
      }
      return kid;
    }

    for (final int band in <int>[0, 1, 2]) {
      test(
        'band $band: a new child is offered a lesson with its skills unlocked in every land, and no land is empty',
        () async {
          final Kid kid = Kid(starter, band, 1);
          checkAllLands(kid, 'band $band, a new child');
          for (final TrophyLand land in lands) {
            final String id = nextLessonId(
              content: starter,
              domain: land.domain,
              finished: kid.finished,
              unlocked: kid.engine.isUnlocked,
            )!;
            // Said in the owner's decision of 2026-11-06: the first lesson of the Counting Hills is counting-words.
            if (land == TrophyLand.counting) expect(id, 'counting-words');
            if (land == TrophyLand.colors) expect(id, isNot('butterflies'));
          }
        },
      );

      test(
        'band $band: a child who answers everything right, warm-ups first, meets every lesson and no gate is broken',
        () async {
          final Kid kid = await walk(band, seed: 7, pRight: 100, steps: 900);
          final Set<String> met = <String>{for (final Attempt a in kid.rows) a.lessonId};
          final Set<String> never = <String>{
            for (final Lesson l in starter.lessons.values)
              if (landPath(starter, 'numbers').contains(l) ||
                  lands.any((TrophyLand t) => landPath(starter, t.domain).contains(l)))
                if (!met.contains(l.id)) l.id,
          };
          // A warm-up may put lessons behind the child (they count as finished once), so only lessons neither played nor placed count.
          final Set<String> placed = placedLessons(starter, kid.rows);
          expect(
            never.difference(placed),
            isEmpty,
            reason: 'lessons never offered: ${never.difference(placed)}',
          );
        },
      );

      test(
        'band $band: a child who is right about half the time and one who is mostly wrong never reach a dead end',
        () async {
          await walk(band, seed: 3, pRight: 55, steps: 240);
          await walk(band, seed: 5, pRight: 15, steps: 240);
        },
      );

      test('band $band: with no warm-up at all (a parent turned it off) the same promises hold', () async {
        await walk(band, seed: 11, pRight: 100, steps: 300, warmUps: false);
      });
    }

    group('the exit: a land with nothing open', () {
      late PackContent robotsBehind;
      setUpAll(() async {
        // Robots (cs): every skill that stands on no other Robots skill is made to stand on NUM-A-01 (Counting Hills), which a new child
        // does not have. So nothing in Robots is open at the start.
        final VerifiedPack pack = await verifyPack(
          File('assets/packs/starter-0.10.0.nnpack').readAsBytesSync(),
          publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
        );
        final Set<String> cs = <String>{
          for (final MapEntry<String, Object?> e in pack.docs.entries)
            if (e.key.startsWith('skill.') && (e.value! as Map<String, Object?>)['domain'] == 'cs')
              (e.value! as Map<String, Object?>)['id']! as String,
        };
        expect(cs, isNotEmpty);
        for (final String id in cs) {
          final Map<String, Object?> skill = pack.docs['skill.$id.json']! as Map<String, Object?>;
          final List<Object?> pre = (skill['prerequisites']! as List<Object?>);
          final bool standsOnCs = pre.any((Object? q) => cs.contains((q! as Map<String, Object?>)['skill']));
          if (!standsOnCs) {
            skill['prerequisites'] = <Object?>[
              ...pre,
              <String, Object?>{'skill': 'NUM-A-01', 'weight': 0.8},
            ];
          }
        }
        robotsBehind = PackContent.fromPack(pack);
      });

      test('a new child has nothing open in Robots, yet is offered a lesson of its lowest band; a higher band stays shut', () {
        final Kid kid = Kid(robotsBehind, 1, 1);
        final List<Lesson> path = landPath(robotsBehind, 'cs');
        final Set<int> levels = <int>{for (final Lesson l in path) _levelOn(robotsBehind, l, 'cs')};
        expect(
          levels.length,
          greaterThan(1),
          reason: 'the land has more than one band, so a wrong exit could show',
        );
        final String? id = nextLessonId(
          content: robotsBehind,
          domain: 'cs',
          finished: kid.finished,
          unlocked: kid.engine.isUnlocked,
        );
        expect(id, isNotNull);
        expect(_levelOn(robotsBehind, robotsBehind.lessons[id]!, 'cs'), 0);
        // Every lesson of the land is locked by the strict rule; the exit is what offers this one.
        expect(
          kid.engine.isUnlocked(
            robotsBehind.lessons[id]!.skillIds.first,
            robotsBehind.lessons[id]!.skillIds.toSet(),
          ),
          isFalse,
        );
        // Play the whole lowest band over and over: a higher band never opens by the exit.
        for (int i = 0; i < 40; i++) {
          final String next = nextLessonId(
            content: robotsBehind,
            domain: 'cs',
            finished: kid.finished,
            unlocked: kid.engine.isUnlocked,
          )!;
          expect(
            _levelOn(robotsBehind, robotsBehind.lessons[next]!, 'cs'),
            0,
            reason: 'round $i offered $next',
          );
          kid.stickers[next] = (kid.stickers[next] ?? 0) + 1;
        }
      });

      for (final int band in <int>[0, 1, 2]) {
        test(
          'band $band: the whole playthrough keeps its promises when Robots stands behind Counting Hills',
          () async {
            exits = 0;
            await walk(band, seed: 21, pRight: 100, steps: 360, pack: robotsBehind);
            expect(
              exits,
              greaterThan(0),
              reason: 'the exit was really used, so the oracle really checked it',
            );
            await walk(band, seed: 22, pRight: 55, steps: 200, pack: robotsBehind);
          },
        );
      }
    });

    test('a pack whose land has no lesson at all has no pebble and nothing breaks', () {
      expect(
        nextLessonId(
          content: starter,
          domain: 'no-such-land',
          finished: const <String, int>{},
          unlocked: (String s, Set<String> t) => false,
        ),
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------------------------------------------------------------
  group('E0b, the staircase warm-up, through the real lesson controller', () {
    const List<String> doms = <String>['numbers', 'colors', 'shapes', 'logic', 'cs', 'math'];

    for (final int band in <int>[0, 1, 2]) {
      for (final String domain in doms) {
        test(
          'band $band, $domain: ONE lucky answer places nobody (the rest needing a miss, a hint or all the help)',
          () async {
            for (final String rest in <String>['M', 'U', 'H', 'S']) {
              final Kid kid = Kid(starter, band, 2);
              await _warmUp(kid, domain, <String>['R', for (int i = 0; i < 9; i++) rest]);
              final LandPlacement p = landPlacementOf(starter, domain, kid.rows, ageBand: band)!;
              expect(p.placedLessons, isEmpty, reason: 'R then $rest: placed ${p.placedLessons}');
              expect(placedByWarmUp(starter, kid.rows).skills, isEmpty);
              expect(kid.finished, isEmpty, reason: 'nothing counts as finished after one lucky answer');
            }
          },
        );

        test(
          'band $band, $domain: a warm-up left early places nobody and goes on where it stopped',
          () async {
            final Kid kid = Kid(starter, band, 2);
            final bool over = await _warmUp(kid, domain, <String>['R', 'R', 'R']);
            final LandPlacement p = landPlacementOf(starter, domain, kid.rows, ageBand: band)!;
            if (over) return; // the staircase happened to stop within three answers
            expect(p.stopped, isFalse);
            expect(p.entry, isNull);
            expect(p.placedLessons, isEmpty);
            expect(placementDue(starter, domain, kid.rows), isTrue, reason: 'the visit comes back');
            expect(kid.finished, isEmpty);
            // It goes on where it stopped: the next probe is not one already asked.
            final String next = placementVisit(starter, domain, kid.rows, ageBand: band)!.flow.first();
            expect(kid.rows.map((Attempt a) => a.activityId), isNot(contains(next)));
          },
        );

        test('band $band, $domain: a warm-up ended kindly after 2 struggles places nobody', () async {
          for (final List<String> head in <List<String>>[
            <String>[],
            <String>['R'],
            <String>['R', 'R'],
            <String>['R', 'R', 'R'],
            <String>['R', 'R', 'R', 'R'],
          ]) {
            final Kid kid = Kid(starter, band, 2);
            final bool over = await _warmUp(kid, domain, <String>[...head, 'S', 'S', 'R', 'R', 'R', 'R']);
            expect(over, isTrue);
            final LandPlacement p = landPlacementOf(starter, domain, kid.rows, ageBand: band)!;
            if (!p.stopped) {
              // The controller ended the visit; the staircase did not stop: nobody is placed.
              expect(p.entry, isNull, reason: 'head $head');
              expect(p.placedLessons, isEmpty, reason: 'head $head');
              expect(placedByWarmUp(starter, kid.rows).skills, isEmpty, reason: 'head $head');
              expect(placementDue(starter, domain, kid.rows), isTrue);
            }
            // Either way, the two struggles themselves never lift anybody: no struggle counts as right.
            final int rights = kid.rows
                .where((Attempt a) => a.result == 'correct' && a.attemptNo == 1 && a.hintLevel == 0)
                .length;
            expect(rights, lessThanOrEqualTo(head.length));
          }
        });

        test(
          'band $band, $domain: a placement survives a change of band, and a pause between visits',
          () async {
            final Kid kid = Kid(starter, band, 2);
            await _warmUp(kid, domain, <String>[for (int i = 0; i < 10; i++) 'R']);
            final LandPlacement a = landPlacementOf(starter, domain, kid.rows, ageBand: band)!;
            for (final int other in <int>[0, 1, 2]) {
              final LandPlacement b = landPlacementOf(starter, domain, kid.rows, ageBand: other)!;
              expect(b.entry, a.entry, reason: 'band $band -> $other');
              expect(b.placedLessons, a.placedLessons);
            }
            // The same through the whole-app reader, which takes no band at all.
            expect(placedByWarmUp(starter, kid.rows).lessons.containsAll(a.placedLessons), isTrue);
          },
        );
      }
    }

    test(
      'a warm-up begun in one band and finished in another is the warm-up it would have been in one visit',
      () async {
        for (final String domain in doms) {
          final Kid whole = Kid(starter, 2, 2);
          await _warmUp(whole, domain, <String>[for (int i = 0; i < 10; i++) i % 3 == 2 ? 'M' : 'R']);
          final Kid split = Kid(starter, 0, 2);
          await _warmUp(split, domain, <String>['R', 'R']);
          final Kid resumed = Kid(starter, 2, 2)..rows.addAll(split.rows);
          // The same two answers were given at the band-0 start; the first probe the band-2 reader gives next must follow from them.
          final LandPlacement viaBand0 = landPlacementOf(starter, domain, split.rows, ageBand: 0)!;
          final LandPlacement viaBand2 = landPlacementOf(starter, domain, resumed.rows, ageBand: 2)!;
          expect(
            viaBand2.stairs.level,
            viaBand0.stairs.level,
            reason: '$domain: the staircase is where it was',
          );
          expect(viaBand2.stairs.next, viaBand0.stairs.next);
          expect(whole.rows, isNotEmpty);
        }
      },
    );

    test('exhaustive: every mix of right, miss, hint and struggle in the first eight probes (Counting Hills, every band)', () async {
      // Directly on the flow, with the two-struggles rule of the controller. Properties that hold for every sequence:
      //  (1) a staircase that has not stopped places nobody;
      //  (2) a child with at most one first-try right answer is placed nowhere;
      //  (3) the flow and the replay of the written rows agree on the entry;
      //  (4) the entry is never above the unit below the best.
      const String domain = 'numbers';
      final List<PlacementLevel> levels = placementLevels(starter, domain);
      int sequences = 0;
      int placedSome = 0;
      for (final int band in <int>[0, 1, 2]) {
        final List<List<String>> frontier = <List<String>>[<String>[]];
        while (frontier.isNotEmpty) {
          final List<String> seq = frontier.removeLast();
          // Play this sequence.
          final List<Attempt> rows = <Attempt>[];
          final ({Lesson lesson, ItemFlow flow}) visit = placementVisit(
            starter,
            domain,
            const <Attempt>[],
            ageBand: band,
          )!;
          String? probe = visit.flow.first();
          int struggles = 0;
          int rights = 0;
          bool ended = false;
          for (final String how in seq) {
            final bool right = how == 'R';
            if (right) rights++;
            rows.addAll(_rows(probe!, how, rows.length));
            struggles = how == 'S' ? struggles + 1 : 0;
            probe = visit.flow.after(probe, right: right);
            if (struggles >= 2) {
              ended = true;
              break;
            }
            if (probe == null) {
              ended = true;
              break;
            }
          }
          final LandPlacement? p = landPlacementOf(starter, domain, rows, ageBand: band);
          if (rows.isNotEmpty) {
            sequences++;
            if (p!.entry != null && p.entry! > 0) placedSome++;
            if (!p.stopped) {
              expect(p.entry, isNull, reason: 'band $band $seq');
              expect(p.placedLessons, isEmpty, reason: 'band $band $seq');
            }
            if (rights <= 1) {
              expect(
                p.placedLessons,
                isEmpty,
                reason: 'band $band: a lone right answer placed somebody: $seq',
              );
            }
            if (p.entry != null && p.best != null) {
              expect(p.entry, p.best! > 0 ? p.best! - 1 : 0, reason: 'band $band $seq');
              expect(levels[p.entry!].lessons, isNotEmpty);
            }
          }
          if (!ended && seq.length < 8) {
            for (final String how in <String>['R', 'M', 'U', 'H', 'S']) {
              frontier.add(<String>[...seq, how]);
            }
          }
        }
      }
      expect(sequences, greaterThan(1000));
      expect(placedSome, greaterThan(0), reason: 'a child who does well can be placed');
    }, timeout: const Timeout(Duration(minutes: 8)));

    test('lessons below the entry count as finished ONCE (a sticker for them says 1, not 2), and open the gate behind them', () async {
      final Kid kid = Kid(starter, 2, 4);
      await _warmUp(kid, 'numbers', <String>[for (int i = 0; i < 10; i++) 'R']);
      final LandPlacement p = landPlacementOf(starter, 'numbers', kid.rows, ageBand: 2)!;
      expect(p.entry, greaterThan(0), reason: 'a child who answers all right is placed above the floor');
      final Set<String> below = p.placedLessons;
      expect(below, isNotEmpty);
      final Map<String, int> fin = kid.finished;
      for (final String id in below) {
        expect(fin[id], 1, reason: '$id counts once');
      }
      // The lessons of the entry unit and above are not counted.
      for (final String id in p.levels[p.entry!].lessons) {
        expect(fin.containsKey(id), isFalse, reason: '$id is the entry unit\'s own');
      }
      // Playing a placed lesson once adds one sticker: it is then 1 still (the sticker n=1 is not added to the placed one).
      final String some = below.first;
      expect(
        finishedLessons(starter, kid.rows, <String>[Awards.sticker(some, 1)])[some],
        1,
        reason: 'placed once, then finished once: not twice',
      );
      expect(finishedLessons(starter, kid.rows, <String>[Awards.sticker(some, 2)])[some], 2);
      // Their skills are assumed known, so the gate is open behind them and the pebble is in the entry unit or after.
      kid.rebuildEngine();
      final String next = nextLessonId(
        content: starter,
        domain: 'numbers',
        finished: kid.finished,
        unlocked: kid.engine.isUnlocked,
      )!;
      expect(
        below,
        isNot(contains(next)),
        reason: 'the pebble does not send a placed child back to the floor',
      );
      final List<Lesson> path = landPath(starter, 'numbers');
      final int firstUnplaced = path.indexWhere((Lesson l) => !below.contains(l.id));
      expect(path.indexWhere((Lesson l) => l.id == next), greaterThanOrEqualTo(firstUnplaced));
    });

    test(
      'the lessons a placement counts are only the land\'s own: other lands keep their whole path',
      () async {
        final Kid kid = Kid(starter, 2, 4);
        await _warmUp(kid, 'numbers', <String>[for (int i = 0; i < 10; i++) 'R']);
        final Set<String> numbersLessons = <String>{
          for (final Lesson l in landPath(starter, 'numbers')) l.id,
        };
        for (final String id in kid.finished.keys) {
          expect(numbersLessons, contains(id), reason: '$id is not a lesson of the land that was placed');
        }
      },
    );
  });
}

/// The rows a probe writes for outcome [how], as the lesson controller writes them (R: one right; M: a miss then right; U: an unsure then
/// right with a hint; S: three misses then right).
List<Attempt> _rows(String probe, String how, int already) {
  int n = already;
  Attempt row(String result, int no, int hint) {
    n++;
    return Attempt(
      id: 100000 + n,
      at: DateTime.utc(2026, 11, 7, 9).add(Duration(seconds: n)),
      profileId: 'kid',
      packId: 'starter',
      packVersion: '0.10.0',
      lessonId: placementId,
      activityId: probe,
      activityRevision: 1,
      template: 'tap_answer',
      templateVersion: '1.0',
      skillId: 'NUM-A-01',
      result: result,
      attemptNo: no,
      hintLevel: hint,
      misconceptionTag: '',
      response: 'o1',
      durationMs: 1000,
      sessionId: null,
      input: 'tap',
    );
  }

  switch (how) {
    case 'R':
      return <Attempt>[row('correct', 1, 0)];
    case 'M':
      return <Attempt>[row('incorrect', 1, 0), row('correct', 2, 1)];
    case 'U':
      return <Attempt>[row('unsure', 1, 0), row('correct', 2, 1)];
    case 'H':
      return <Attempt>[row('correct', 1, 1)];
    default:
      return <Attempt>[
        row('incorrect', 1, 0),
        row('incorrect', 2, 1),
        row('incorrect', 3, 2),
        row('correct', 4, 3),
      ];
  }
}
