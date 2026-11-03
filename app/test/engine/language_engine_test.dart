// F9 of docs/languages/frame.md section 3: what the engine needs for the language courses, as pure functions with tests. Every
// course here is a small fixture (not real content).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/gates.dart';
import 'package:nitznutz/engine/graph.dart';
import 'package:nitznutz/engine/outcome.dart';
import 'package:nitznutz/engine/params.dart';
import 'package:nitznutz/engine/presentation.dart';
import 'package:nitznutz/engine/rollup.dart';
import 'package:nitznutz/engine/session_builder.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'course_fixtures.dart';
import 'fixtures.dart';

SkillNode _eng(String id, {List<String> needs = const <String>[], bool letters = false, String? bundle}) =>
    SkillNode(
      id: id,
      course: Course.eng,
      prerequisites: <String, double>{for (final String n in needs) n: 1},
      letters: letters,
      bundle: bundle,
    );

/// The next thing a builder serves right after a warm-up item.
Pick _afterWarmUp(
  Engine e, {
  int band = 1,
  String course = Course.core,
  Set<String> held = const <String>{},
}) {
  final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(3));
  final ItemMeta any = e.catalog.items.values.firstWhere((ItemMeta i) => i.course == course);
  return b.next(
    SessionContext(
      sessionId: 1,
      band: band,
      now: day0.add(const Duration(days: 30)),
      served: <Served>[Served(any, Phase.warmUp, Result.correct)],
      course: course,
      held: held,
    ),
  );
}

void main() {
  group('presentation band and content level (3.1)', () {
    test('the band comes from the age; a parent\'s override wins; it stays between 0 and 2', () {
      expect(presentationBandFor(ageBand: 2), 2);
      expect(presentationBandFor(ageBand: 2, override: 0), 0);
      expect(presentationBandFor(ageBand: 0, override: 1), 1);
      expect(presentationBandFor(ageBand: 1, override: 7), 2);
      expect(presentationBandFor(ageBand: 1, override: -3), 0);
    });

    test('the content level is the band letter of the skill id, whatever the presentation', () {
      expect(contentLevelOf('ENG-A-01'), 0);
      expect(contentLevelOf('RUS-B-24.G10'), 1);
      expect(contentLevelOf('HEB-C-06'), 2);
    });

    test('how a screen looks and paces under each band', () {
      final PresentationSpec a = presentationSpec(0);
      final PresentationSpec b = presentationSpec(1);
      final PresentationSpec c = presentationSpec(2);
      expect(<int?>[a.maxChoices, b.maxChoices, c.maxChoices], <int?>[3, null, null]);
      expect(<int>[a.itemsMin, a.itemsMax], <int>[3, 5]);
      expect(<int>[b.itemsMin, b.itemsMax], <int>[5, 8]);
      expect(c.itemsMax, 12);
      expect(<int>[a.sessionMinutes, b.sessionMinutes, c.sessionMinutes], <int>[8, 12, 15]);
      expect(<bool>[a.oneInstruction, b.oneInstruction], <bool>[true, false]);
      expect(<bool>[a.readingDemand, b.readingDemand, c.readingDemand], <bool>[false, true, true]);
    });

    test('a course may set a shorter visit: English 6-8, 10-12 and 12-15 minutes', () {
      expect(
        <int>[for (int b = 0; b < 3; b++) presentationSpec(b, course: Course.eng).sessionMinutes],
        <int>[7, 11, 13],
      );
      expect(presentationSpec(0, course: Course.heb).sessionMinutes, 8);
      expect(presentationSpec(0, course: Course.eng, params: const EngineParams()).sessionMinutes, 7);
    });

    test('letter work is never offered under Band A, except Hebrew A-10 to A-12', () {
      final SkillNode letter = _eng('ENG-B-16', letters: true);
      final SkillNode oral = _eng('ENG-B-01');
      expect(offeredUnder(0, letter), isFalse);
      expect(offeredUnder(1, letter), isTrue);
      expect(
        offeredUnder(0, oral),
        isTrue,
        reason: 'a level B skill that is not letters is fine under Band A',
      );
      for (final String id in <String>['HEB-A-10', 'HEB-A-11', 'HEB-A-12']) {
        expect(
          offeredUnder(0, SkillNode(id: id, course: Course.heb, letters: true)),
          isTrue,
          reason: id,
        );
      }
      expect(offeredUnder(0, const SkillNode(id: 'HEB-B-14', course: Course.heb, letters: true)), isFalse);
    });

    test('a 7-year-old new to English starts at the first skill with the oldest band\'s pace', () {
      final Engine e = engineOf(
        catalogOf(<SkillNode>[
          _eng('ENG-A-01'),
          _eng('ENG-A-02', needs: <String>['ENG-A-01']),
        ]),
      );
      final Pick p = _afterWarmUp(e, band: 2, course: Course.eng);
      expect(p, isA<ServeItem>());
      expect((p as ServeItem).item.primarySkill, 'ENG-A-01');
      expect(
        SessionBuilder(engine: e, random: math.Random(1)).totalItems(2, course: Course.eng),
        greaterThan(8),
      );
    });

    test(
      'a young child who has the skill below can be given a level B skill under Band A, but not its letters',
      () {
        final Engine e = engineOf(
          catalogOf(<SkillNode>[
            _eng('ENG-A-01'),
            _eng('ENG-B-01', needs: <String>['ENG-A-01']),
            _eng('ENG-B-16', needs: <String>['ENG-A-01'], letters: true),
          ]),
        );
        master(Story(e), 'ENG-A-01');
        final Set<String> served = <String>{};
        for (int seed = 0; seed < 8; seed++) {
          final Pick p = SessionBuilder(engine: e, random: math.Random(seed)).next(
            SessionContext(
              sessionId: seed + 1,
              band: 0,
              now: day0.add(const Duration(days: 30)),
              served: <Served>[Served(e.catalog.items['ENG-A-01.0']!, Phase.warmUp, Result.correct)],
              course: Course.eng,
            ),
          );
          if (p is ServeItem && p.phase == Phase.focus) served.add(p.item.primarySkill);
        }
        expect(served, <String>{'ENG-B-01'}, reason: 'level B with Band A presentation; the letters wait');
      },
    );
  });

  group('sub-skills and roll-ups (3.3.2)', () {
    final List<SkillNode> skills = <SkillNode>[
      _eng('ENG-A-01'),
      _eng('ENG-B-19'),
      _eng('ENG-B-19.G1', needs: <String>['ENG-A-01']),
      _eng('ENG-B-19.G2', needs: <String>['ENG-A-01']),
      _eng('ENG-C-01', needs: <String>['ENG-B-19']),
    ];

    test('a roll-up is a skill that has dotted groups; its groups are listed in order', () {
      final Catalog c = catalogOf(skills.where((SkillNode s) => s.id != 'ENG-B-19').toList());
      expect(c.subSkills, isEmpty, reason: 'groups with no roll-up in the catalogue are plain skills');
      final Catalog all = catalogOf(skills);
      expect(all.subSkills, <String, List<String>>{
        'ENG-B-19': <String>['ENG-B-19.G1', 'ENG-B-19.G2'],
      });
      expect(all.isRollUp('ENG-B-19'), isTrue);
      expect(all.isRollUp('ENG-B-19.G1'), isFalse);
    });

    test('as a prerequisite a roll-up means all its groups, each with the weight of the edge', () {
      final Catalog c = catalogOf(skills);
      expect(c.skills['ENG-C-01']!.prerequisites.keys.toSet(), <String>{'ENG-B-19.G1', 'ENG-B-19.G2'});
      expect(c.skills['ENG-B-19.G1']!.prerequisites.keys, <String>['ENG-A-01']);
      final SkillGraph g = SkillGraph(c);
      expect(g.depth('ENG-C-01'), 2);
      expect(
        g.report().where((String l) => l.contains('ENG-B-19 ')),
        isEmpty,
        reason: 'no report on the roll-up',
      );
    });

    test(
      'the roll-up has no estimate of its own: it is fresh when its groups are, durable when they are',
      () {
        final Engine e = engineOf(catalogOf(skills));
        final Story s = Story(e);
        master(s, 'ENG-A-01');
        expect(e.statusOf('ENG-B-19', s.at), SkillStatus.ready);
        expect(e.isUnlocked('ENG-C-01'), isFalse);
        master(s, 'ENG-B-19.G1');
        expect(e.statusOf('ENG-B-19.G1', s.at), SkillStatus.freshMastery);
        expect(e.statusOf('ENG-B-19', s.at), SkillStatus.learning, reason: 'one group of two');
        expect(e.isUnlocked('ENG-C-01'), isFalse, reason: 'all groups, not one');
        master(s, 'ENG-B-19.G2');
        expect(e.statusOf('ENG-B-19', s.at), SkillStatus.freshMastery);
        expect(e.isUnlocked('ENG-C-01'), isTrue);
        expect(e.state.skills.containsKey('ENG-B-19'), isFalse, reason: 'no estimate, no state');
        s.days(9);
        s.right('ENG-B-19.G1.1');
        s.days(1);
        s.right('ENG-B-19.G1.0');
        s.right('ENG-B-19.G1.2');
        expect(e.statusOf('ENG-B-19', s.at), SkillStatus.freshMastery, reason: 'one group durable, one not');
      },
    );

    test('the table of roll-up statuses', () {
      const SkillStatus d = SkillStatus.durableMastery;
      const SkillStatus f = SkillStatus.freshMastery;
      expect(rollUpStatus(const <SkillStatus>[]), SkillStatus.notStarted);
      expect(rollUpStatus(<SkillStatus>[d, d]), d);
      expect(rollUpStatus(<SkillStatus>[d, f]), f);
      expect(rollUpStatus(<SkillStatus>[f, SkillStatus.needsRevisit]), SkillStatus.needsRevisit);
      expect(rollUpStatus(<SkillStatus>[f, SkillStatus.learning]), SkillStatus.learning);
      expect(rollUpStatus(<SkillStatus>[SkillStatus.needsRevisit, SkillStatus.ready]), SkillStatus.learning);
      expect(rollUpStatus(<SkillStatus>[SkillStatus.gap, SkillStatus.ready]), SkillStatus.learning);
      expect(rollUpStatus(<SkillStatus>[SkillStatus.ready, SkillStatus.notStarted]), SkillStatus.ready);
      expect(rollUpStatus(<SkillStatus>[SkillStatus.notStarted]), SkillStatus.notStarted);
    });

    test('the representation statistics of the groups are the roll-up\'s family', () {
      expect(<String>{for (final SkillNode s in skills) s.family}, <String>{'ENG-A', 'ENG-B', 'ENG-C'});
    });

    test('the builder never offers a roll-up, only its groups', () {
      final Engine e = engineOf(catalogOf(skills));
      master(Story(e), 'ENG-A-01');
      final Pick p = _afterWarmUp(e, course: Course.eng);
      expect((p as ServeItem).item.primarySkill, startsWith('ENG-B-19.G'));
    });

    test('a gate or a parent sees a roll-up as the lowest level of its groups', () {
      final Engine e = engineOf(catalogOf(skills));
      final Story s = Story(e);
      master(s, 'ENG-B-19.G1');
      expect(masteryLevels(e)['ENG-B-19.G1'], MasteryLevel.fresh);
      expect(masteryLevels(e).containsKey('ENG-B-19'), isFalse);
      master(s, 'ENG-B-19.G2');
      expect(masteryLevels(e)['ENG-B-19'], MasteryLevel.fresh);
    });
  });

  group('letter bundles (3.3.3)', () {
    final List<SkillNode> skills = <SkillNode>[
      _eng('ENG-A-01'),
      _eng('ENG-A-02'),
      _eng('ENG-B-16', needs: <String>['ENG-A-01'], bundle: 'eng.g1'),
      _eng('ENG-B-19.G1', needs: <String>['ENG-A-02'], bundle: 'eng.g1'),
      _eng('ENG-B-19', needs: const <String>[]),
      _eng('ENG-B-17', needs: <String>['ENG-A-01'], bundle: 'eng.g2'),
      _eng('ENG-B-19.G2', needs: <String>['ENG-A-01'], bundle: 'eng.g2'),
      _eng('ENG-B-18', needs: <String>['ENG-A-01']),
    ];

    test('the facets of a bundle are listed together', () {
      final Catalog c = catalogOf(skills);
      expect(c.bundles['eng.g1'], <String>['ENG-B-16', 'ENG-B-19.G1']);
      expect(c.unitOf('ENG-B-16'), 'eng.g1');
      expect(c.unitOf('ENG-B-18'), 'ENG-B-18');
    });

    test('a bundle unlocks as one: when the prerequisites of all its facets are met', () {
      final Engine e = engineOf(catalogOf(skills));
      final Story s = Story(e);
      master(s, 'ENG-A-01');
      expect(e.isUnlocked('ENG-B-16'), isFalse, reason: 'its twin still waits for ENG-A-02');
      expect(e.isUnlocked('ENG-B-19.G1'), isFalse);
      expect(e.isUnlocked('ENG-B-17'), isTrue, reason: 'another bundle, whose facets need only ENG-A-01');
      master(s, 'ENG-A-02');
      expect(e.isUnlocked('ENG-B-16'), isTrue);
      expect(e.isUnlocked('ENG-B-19.G1'), isTrue);
    });

    test('the facets do not need each other, and mastery stays per facet', () {
      final Engine e = engineOf(catalogOf(skills));
      final Story s = Story(e);
      master(s, 'ENG-A-01');
      master(s, 'ENG-A-02');
      master(s, 'ENG-B-16');
      expect(e.statusOf('ENG-B-16', s.at), SkillStatus.freshMastery);
      expect(e.statusOf('ENG-B-19.G1', s.at), SkillStatus.ready, reason: 'its own estimate');
    });

    /// A child who has the two skills below and has learnt [begun] in session 4 (the facets are fresh, so none of them is
    /// offered again), and the skills the builder then picks to start next.
    Set<String> startedNext(List<String> begun) {
      final Engine e = engineOf(catalogOf(skills));
      final Story s = Story(e);
      master(s, 'ENG-A-01');
      master(s, 'ENG-A-02');
      for (final String id in begun) {
        master(s, id, session: 4);
      }
      expect(e.state.newSkillsInSession[4]!.map(e.catalog.unitOf).toSet().length, begun.length > 2 ? 2 : 1);
      final Set<String> out = <String>{};
      for (int seed = 0; seed < 10; seed++) {
        final Pick p = SessionBuilder(engine: e, random: math.Random(seed)).next(
          SessionContext(
            sessionId: 4,
            band: 1,
            now: s.at,
            served: <Served>[Served(e.catalog.items['ENG-A-01.0']!, Phase.warmUp, Result.correct)],
            course: Course.eng,
          ),
        );
        if (p is ServeItem && p.phase == Phase.focus) out.add(p.item.primarySkill);
      }
      return out;
    }

    test('a bundle counts as one new skill against the limit of two per session', () {
      // One bundle begun (two facets, one unit): another unit may still begin.
      final Set<String> second = startedNext(<String>['ENG-B-16', 'ENG-B-19.G1']);
      expect(second, isNotEmpty);
      expect(
        second,
        everyElement(isIn(<String>{'ENG-B-17', 'ENG-B-18', 'ENG-B-19.G2'})),
        reason: 'a second unit',
      );

      // Two units begun (the first bundle, and one facet of the second): the third unit, ENG-B-18, may not begin, but the
      // other facet of the second bundle may.
      expect(startedNext(<String>['ENG-B-16', 'ENG-B-19.G1', 'ENG-B-17']), <String>{'ENG-B-19.G2'});
    });
  });

  group('word sets and letter groups: set coverage (3.3.4)', () {
    // A set of three words, each word an item in two representations; the third representation is the check.
    Engine setEngine() {
      const SkillNode set = SkillNode(id: 'ENG-A-05', course: Course.eng, setCoverage: true);
      final List<ItemMeta> items = <ItemMeta>[
        for (final String w in <String>['cat', 'dog', 'fish'])
          for (final (int r, Representation rep) in <(int, Representation)>[
            (0, Representation.concrete),
            (1, Representation.pictorial),
          ])
            ItemMeta(
              id: 'w.$w.$r',
              course: Course.eng,
              skills: const <String, double>{'ENG-A-05': 1},
              representation: rep,
              variantGroup: 'word.$w',
              optionCount: 3,
            ),
        const ItemMeta(
          id: 'w.check',
          course: Course.eng,
          skills: <String, double>{'ENG-A-05': 1},
          representation: Representation.symbolic,
          checkType: CheckType.reverse,
          variantGroup: 'word.check',
        ),
      ];
      return engineOf(Catalog(skills: <SkillNode>[set], items: items));
    }

    test('half the set answered right many times is not enough for fresh mastery', () {
      final Engine e = setEngine();
      final Story s = Story(e);
      for (int i = 0; i < 4; i++) {
        s.right('w.cat.0');
        s.right('w.dog.1');
      }
      s.days(1);
      s.right('w.check');
      s.right('w.cat.1');
      s.right('w.dog.0');
      final SkillState st = e.state.skills['ENG-A-05']!;
      expect(st.p, greaterThan(0.95));
      expect(st.successes, greaterThan(4));
      expect(st.freshAt, isNull, reason: 'fish was never answered right');
      expect(e.uncoveredGroups('ENG-A-05'), <String>{'word.fish'});
    });

    test('once every word has been answered right once without a hint, the set is fresh', () {
      final Engine e = setEngine();
      final Story s = Story(e);
      for (int i = 0; i < 4; i++) {
        s.right('w.cat.0');
        s.right('w.dog.1');
      }
      s.days(1);
      s.right('w.fish.0');
      s.right('w.check');
      expect(e.state.skills['ENG-A-05']!.freshAt, isNotNull);
      expect(e.uncoveredGroups('ENG-A-05'), isEmpty);
    });

    test('a word answered right only with a hint, or only wrong, does not count', () {
      final Engine e = setEngine();
      final Story s = Story(e);
      for (int i = 0; i < 4; i++) {
        s.right('w.cat.0');
        s.right('w.dog.1');
      }
      s.days(1);
      s.right('w.fish.0', hint: 1);
      s.wrong('w.fish.1');
      s.right('w.check');
      expect(e.state.skills['ENG-A-05']!.freshAt, isNull);
      expect(e.uncoveredGroups('ENG-A-05'), <String>{'word.fish'});
    });

    test('a skill that is not a set is unaffected', () {
      final Engine e = engineOf(catalogOf(<SkillNode>[_eng('ENG-A-06')]));
      master(Story(e), 'ENG-A-06');
      expect(e.state.skills['ENG-A-06']!.freshAt, isNotNull);
      expect(e.uncoveredGroups('ENG-A-06'), isEmpty);
    });

    test('the items rotate through the words not yet answered right', () {
      final Engine e = setEngine();
      final Story s = Story(e);
      s.right('w.cat.0');
      s.right('w.dog.0');
      final Set<String> groups = <String>{};
      for (int seed = 0; seed < 12; seed++) {
        final Pick p = SessionBuilder(engine: e, random: math.Random(seed)).next(
          SessionContext(
            sessionId: 1,
            band: 1,
            now: s.at,
            served: <Served>[Served(e.catalog.items['w.cat.0']!, Phase.warmUp, Result.correct)],
            course: Course.eng,
          ),
        );
        if (p is ServeItem) groups.add(p.item.variantGroup);
      }
      expect(groups, isNotEmpty);
      expect(
        groups,
        everyElement(isIn(<String>{'word.fish', 'word.check'})),
        reason: 'only the uncovered words',
      );
    });
  });

  group('the sound-right outcome (3.3.5)', () {
    test('the book spelling is correct', () {
      for (final SoundRightPolicy p in SoundRightPolicy.values) {
        final ScoredSpelling r = scoreSpelling(SpellingOutcome.exact, p);
        expect(r.result, Result.correct);
        expect(r.detail.wire, 'exact');
        expect(r.countsAsMisconception, isFalse);
      }
    });

    test('where the skill accepts it, right by sound is correct and the tag is only "on the way"', () {
      final ScoredSpelling r = scoreSpelling(SpellingOutcome.soundRight, SoundRightPolicy.accepts);
      expect(r.result, Result.correct);
      expect(r.detail.wire, 'sound_right');
      expect(r.onTheWay, isTrue);
      expect(r.countsAsMisconception, isFalse);
    });

    test('where the skill teaches the convention, right by sound is incorrect and the tag is evidence', () {
      final ScoredSpelling r = scoreSpelling(SpellingOutcome.soundRight, SoundRightPolicy.teaches);
      expect(r.result, Result.incorrect);
      expect(r.detail.wire, 'sound_right');
      expect(r.countsAsMisconception, isTrue);
      expect(r.onTheWay, isFalse);
    });

    test('not yet is incorrect in every skill, and the default policy is strict', () {
      for (final SoundRightPolicy p in SoundRightPolicy.values) {
        final ScoredSpelling r = scoreSpelling(SpellingOutcome.notYet, p);
        expect(r.result, Result.incorrect);
        expect(r.detail.wire, '');
        expect(r.countsAsMisconception, isTrue);
      }
      expect(const SkillNode(id: 'ENG-B-20').soundRight, SoundRightPolicy.teaches);
    });

    test('the engine takes it as the policy says: no misconception from an accepted spelling, evidence from a taught one', () {
      const String tag = 'eng.wr.c_k';
      Engine build(SoundRightPolicy policy) => engineOf(
        Catalog(
          skills: <SkillNode>[SkillNode(id: 'ENG-B-20', course: Course.eng, soundRight: policy)],
          items: <ItemMeta>[
            for (int i = 0; i < 3; i++)
              ItemMeta(
                id: 's.$i',
                course: Course.eng,
                skills: const <String, double>{'ENG-B-20': 1},
                variantGroup: 'g$i',
                tags: const <String>{tag},
              ),
          ],
          tags: const <TagInfo>[
            TagInfo(id: tag, course: Course.eng, skills: <String>['ENG-B-20']),
          ],
        ),
      );
      for (final SoundRightPolicy policy in SoundRightPolicy.values) {
        final Engine e = build(policy);
        final Story s = Story(e);
        for (int i = 0; i < 3; i++) {
          final ScoredSpelling r = scoreSpelling(
            SpellingOutcome.soundRight,
            e.catalog.skills['ENG-B-20']!.soundRight,
          );
          s.answer('s.$i', r.result, tag: tag);
        }
        final bool evidence = e.state.tags[tag]?.status == TagStatus.active;
        expect(evidence, policy == SoundRightPolicy.teaches, reason: policy.name);
        expect(
          e.state.skills['ENG-B-20']!.nCorrect,
          policy == SoundRightPolicy.accepts ? 3 : 0,
          reason: policy.name,
        );
      }
    });
  });

  group('course gates (3.3.6)', () {
    const CourseGate oral = CourseGate(
      id: 'eng.oral',
      course: Course.eng,
      requires: <String>{'ENG-A-01', 'ENG-A-02'},
      requireAtLeast: <SkillQuota>[
        SkillQuota(skills: <String>{'ENG-B-12', 'ENG-B-13', 'ENG-B-14'}, count: 3),
      ],
      holds: <String>{'ENG-B-16', 'ENG-B-17'},
      neverUnderBand: 0,
      durableBelowBand: 2,
      switchName: 'oralOnly',
      switchEffect: SwitchEffect.closes,
    );
    const CourseGate letters = CourseGate(
      id: 'rus.letters',
      course: Course.rus,
      requires: <String>{'RUS-A-12'},
      requireAtLeast: <SkillQuota>[
        SkillQuota(skills: <String>{'RUS-A-20', 'RUS-A-21', 'RUS-A-22', 'RUS-A-23'}, count: 3),
      ],
      holds: <String>{'RUS-B-18'},
      minAge: 5,
      switchName: 'lettersBefore5',
      switchEffect: SwitchEffect.opens,
      routeBypass: <String>{'heritage', 'reader'},
    );
    const Set<String> engSkills = <String>{'ENG-A-01', 'ENG-A-02', 'ENG-B-12', 'ENG-B-13', 'ENG-B-14'};

    GateInput engInput({
      MasteryLevel level = MasteryLevel.durable,
      Set<String> skills = engSkills,
      int ageBand = 1,
      int presentationBand = 1,
      Set<String> switchesOn = const <String>{},
      Set<String> placedOpen = const <String>{},
    }) => GateInput(
      mastery: <String, MasteryLevel>{for (final String s in skills) s: level},
      ageBand: ageBand,
      presentationBand: presentationBand,
      switchesOn: switchesOn,
      placedOpen: placedOpen,
    );

    test('English: open when the oral core and the onset-rime skills are durable', () {
      expect(gateResult(oral, engInput()).open, isTrue);
    });

    test('English: missing skills keep it closed and are named', () {
      final GateResult r = gateResult(oral, engInput(skills: <String>{'ENG-A-01', 'ENG-B-12', 'ENG-B-13'}));
      expect(r.open, isFalse);
      expect(r.reasons, <GateReason>[GateReason.skillsMissing]);
      expect(r.missing, <String>['ENG-A-02', 'ENG-B-14']);
    });

    test('English: Band C may use fresh mastery, Band B needs durable', () {
      expect(gateResult(oral, engInput(level: MasteryLevel.fresh, presentationBand: 2)).open, isTrue);
      expect(gateResult(oral, engInput(level: MasteryLevel.fresh, presentationBand: 1)).open, isFalse);
    });

    test('English: Band A never opens it', () {
      final GateResult r = gateResult(oral, engInput(presentationBand: 0));
      expect(r.open, isFalse);
      expect(r.reasons, <GateReason>[GateReason.bandTooYoung]);
      expect(gateResult(oral, engInput(presentationBand: 0, placedOpen: <String>{'eng.oral'})).open, isFalse);
    });

    test('English: the parent\'s "oral only" keeps it closed, even for a child placed above it', () {
      final GateResult r = gateResult(oral, engInput(switchesOn: <String>{'oralOnly'}));
      expect(r.open, isFalse);
      expect(r.reasons, <GateReason>[GateReason.parentHolds]);
      expect(
        gateResult(oral, engInput(switchesOn: <String>{'oralOnly'}, placedOpen: <String>{'eng.oral'})).open,
        isFalse,
      );
    });

    test('a child placed above a gate has it open', () {
      expect(gateResult(oral, engInput(skills: <String>{}, placedOpen: <String>{'eng.oral'})).open, isTrue);
    });

    GateInput rusInput({
      int ageBand = 1,
      String? route,
      Set<String> switchesOn = const <String>{},
      Set<String> skills = const <String>{'RUS-A-12', 'RUS-A-20', 'RUS-A-21', 'RUS-A-22'},
    }) => GateInput(
      mastery: <String, MasteryLevel>{for (final String s in skills) s: MasteryLevel.fresh},
      ageBand: ageBand,
      presentationBand: ageBand,
      switchesOn: switchesOn,
      route: route,
    );

    test('Russian: A-12 and three themes, and age 5 or more', () {
      expect(gateResult(letters, rusInput()).open, isTrue);
      final GateResult few = gateResult(letters, rusInput(skills: <String>{'RUS-A-12', 'RUS-A-20'}));
      expect(few.open, isFalse);
      expect(few.missing, containsAll(<String>['RUS-A-21', 'RUS-A-22', 'RUS-A-23']));
      final GateResult young = gateResult(letters, rusInput(ageBand: 0));
      expect(young.open, isFalse);
      expect(young.reasons, <GateReason>[GateReason.tooYoung]);
    });

    test('Russian: a heritage speaker or a reader has no age gate, a new learner does', () {
      expect(gateResult(letters, rusInput(ageBand: 0, route: 'heritage')).open, isTrue);
      expect(gateResult(letters, rusInput(ageBand: 0, route: 'reader')).open, isTrue);
      expect(gateResult(letters, rusInput(ageBand: 0, route: 'new')).open, isFalse);
      expect(
        gateResult(letters, rusInput(ageBand: 0, route: 'heritage', skills: <String>{'RUS-A-12'})).open,
        isFalse,
        reason: 'the skills still count',
      );
    });

    test('Russian: the parent can open it', () {
      expect(
        gateResult(
          letters,
          rusInput(ageBand: 0, skills: const <String>{}, switchesOn: <String>{'lettersBefore5'}),
        ).open,
        isTrue,
      );
    });

    test('a closed gate holds its skills back; an open one holds nothing', () {
      expect(heldSkills(<CourseGate>[oral, letters], engInput(skills: <String>{})), <String>{
        'ENG-B-16',
        'ENG-B-17',
        'RUS-B-18',
      });
      expect(heldSkills(<CourseGate>[oral], engInput()), isEmpty);
    });

    test('the builder does not offer a held skill, and does when the gate opens', () {
      final Engine e = engineOf(
        catalogOf(<SkillNode>[
          _eng('ENG-A-01'),
          _eng('ENG-B-16', needs: <String>['ENG-A-01'], letters: true),
          _eng('ENG-B-01', needs: <String>['ENG-A-01']),
        ]),
      );
      final Story story = Story(e);
      master(story, 'ENG-A-01');
      final Pick held = _afterWarmUp(e, course: Course.eng, held: <String>{'ENG-B-16'});
      expect((held as ServeItem).item.primarySkill, 'ENG-B-01');
      // With the gate open the letters are a skill like another: once the first skill has had its share, they come.
      final Pick opened = SessionBuilder(engine: e, random: math.Random(1)).next(
        SessionContext(
          sessionId: 1,
          band: 1,
          now: story.at,
          served: <Served>[
            Served(e.catalog.items['ENG-A-01.0']!, Phase.warmUp, Result.correct),
            for (int k = 0; k < 5; k++) Served(e.catalog.items['ENG-B-01.0']!, Phase.focus, Result.correct),
          ],
          course: Course.eng,
        ),
      );
      expect((opened as ServeItem).item.primarySkill, 'ENG-B-16');
    });

    test('mastery levels are read from the engine\'s state: fresh once, durable after the delayed check', () {
      final Engine e = engineOf(
        catalogOf(
          <SkillNode>[_eng('ENG-A-01')],
          extraItems: const <ItemMeta>[
            ItemMeta(
              id: 'ENG-A-01.new',
              course: Course.eng,
              skills: <String, double>{'ENG-A-01': 1},
              variantGroup: 'ENG-A-01.gnew',
            ),
          ],
        ),
      );
      final Story s = Story(e);
      master(s, 'ENG-A-01');
      expect(masteryLevels(e), <String, MasteryLevel>{'ENG-A-01': MasteryLevel.fresh});
      s.days(8);
      s.right('ENG-A-01.1');
      expect(masteryLevels(e)['ENG-A-01'], MasteryLevel.fresh, reason: 'an item used before fresh mastery');
      s.days(1);
      s.right('ENG-A-01.new');
      expect(masteryLevels(e)['ENG-A-01'], MasteryLevel.durable);
    });
  });

  group('one course per visit (3.5)', () {
    test('a visit over a catalogue of all four courses serves only its own course', () {
      for (final String course in Course.all) {
        final Engine e = engineOf(allCourses());
        final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(7));
        final List<Served> served = <Served>[];
        for (int i = 0; i < 40; i++) {
          final Pick p = b.next(
            SessionContext(sessionId: 1, band: 1, now: day0, served: served, course: course),
          );
          if (p is! ServeItem) break;
          expect(p.item.course, course, reason: '$course visit, item ${i + 1}: ${p.item.id}');
          served.add(Served(p.item, p.phase, Result.correct));
          e.apply(
            AttemptEvent(
              at: day0.add(Duration(seconds: 40 * i)),
              activityId: p.item.id,
              result: Result.correct,
              sessionId: 1,
            ),
          );
        }
        expect(served.length, greaterThan(3), reason: course);
      }
    });

    test(
      'another course\'s misconceptions, gaps and due checks are not repaired or revisited in this visit',
      () {
        final Engine e = engineOf(allCourses());
        final Story s = Story(e);
        // English: an active misconception and a skill that falls due.
        master(s, 'ENG-A-01');
        for (final String item in <String>['ENG-A-01.0', 'ENG-A-01.1', 'ENG-A-01.0']) {
          s.wrong(item, tag: 'eng.ph.dir');
        }
        expect(e.state.activeTags, contains('eng.ph.dir'));
        s.days(30);
        expect(e.dueChecks(s.at), contains('ENG-A-01'));
        for (final String course in <String>[Course.core, Course.heb, Course.rus]) {
          final SessionBuilder b = SessionBuilder(engine: e, random: math.Random(5));
          final List<Served> served = <Served>[];
          for (int i = 0; i < 30; i++) {
            final Pick p = b.next(
              SessionContext(sessionId: 2, band: 1, now: s.at, served: served, course: course),
            );
            if (p is! ServeItem) break;
            expect(p.item.course, course, reason: '$course: ${p.item.id} (${p.phase.name})');
            expect(<Phase>[Phase.repair, Phase.revisit], isNot(contains(p.phase)));
            served.add(Served(p.item, p.phase, Result.correct));
          }
        }
        // And the English visit checks its own skill that fell due (the child has not recovered enough to go on to the next).
        final Pick own = SessionBuilder(engine: e, random: math.Random(5)).next(
          SessionContext(
            sessionId: 3,
            band: 1,
            now: s.at,
            served: <Served>[Served(e.catalog.items['ENG-A-01.0']!, Phase.warmUp, Result.correct)],
            course: Course.eng,
          ),
        );
        expect((own as ServeItem).phase, Phase.revisit);
        expect(own.item.primarySkill, 'ENG-A-01');
      },
    );

    test('an engine built on one course\'s view cannot learn from another course\'s answers', () {
      final Catalog all = allCourses();
      final Engine eng = engineOf(all.forCourse(Course.eng));
      eng.replay(<AttemptEvent>[
        AttemptEvent(at: day0, activityId: 'ENG-A-01.0', result: Result.correct),
        AttemptEvent(at: day0, activityId: 'RUS-A-01.0', result: Result.correct),
        AttemptEvent(at: day0, activityId: 'SK-A-01.0', result: Result.correct),
      ]);
      expect(eng.state.skills.keys, <String>['ENG-A-01']);
    });

    test('the representation statistics are kept per course', () {
      final Engine e = engineOf(allCourses());
      final Story s = Story(e);
      s.right('ENG-A-01.0');
      s.right('RUS-A-01.0');
      expect(e.state.representations.keys, containsAll(<String>['ENG-A|concrete', 'RUS-A|concrete']));
      expect(e.state.representations.keys, isNot(contains('SK-A|concrete')));
    });
  });
}
