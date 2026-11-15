// L7-8, letters by age, level first (docs/milestones/L7.md acceptance criterion 7; docs/languages/frame.md sections 3.1, 3.2 and 3.3.6).
// Each sentence of the criterion is a test here, on the three letters gates as the packs will carry them (test/support/letter_gates.dart:
// validated by the real validator, read by the real adapter), then on the settings, the placement that confirms letters, and the course as
// the app builds it. No letter content is in the packs yet (Band B is not built); the fixtures stand in for it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart'
    show languageCourseOf, languageCoursesProvider, meetLettersOpenProvider;
import 'package:nitznutz/content/engine_adapter.dart' show courseGates, engineCatalog;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/gates.dart';
import 'package:nitznutz/engine/staircase.dart';
import 'package:nitznutz/engine/types.dart' show AttemptEvent, ItemMeta, Result;
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/language_gates.dart' show GateContext, courseGateState;
import 'package:nitznutz/world/language_placement.dart';
import 'package:nitznutz/world/path_gate.dart' show heldLessonIds;
import 'package:nitznutz/world/placement.dart' show placementIdFor;

import 'support/course_history.dart';
import 'support/course_packs.dart';
import 'support/language_content.dart';
import 'support/letter_gates.dart';

// Ages in months: 3;0, 4;11, 5;0, 5;6, 6;0, 6;11, 7;0.
const int _m3 = 36, _m4y11 = 59, _m5 = 60, _m5h = 66, _m6 = 72, _m6y11 = 83, _m7 = 84;

GateInput _in({
  int? months,
  int band = 1,
  Map<String, MasteryLevel> mastery = const <String, MasteryLevel>{},
  Set<String> switchesOn = const <String>{},
  Set<String> placedOpen = const <String>{},
  Set<String> known = const <String>{},
  String? route,
}) => GateInput(
  mastery: mastery,
  ageBand: band,
  ageMonths: months,
  switchesOn: switchesOn,
  placedOpen: placedOpen,
  known: known,
  route: route,
);

Map<String, MasteryLevel> _all(Iterable<String> skills, MasteryLevel level) => <String, MasteryLevel>{
  for (final String s in skills) s: level,
};

/// Every skill the English oral gate asks for (what a child who finished the listening core has).
List<String> get _engCore => (engOralGate['requires']! as List<String>);

void main() {
  late CourseGate eng, rus, heb;

  setUpAll(() {
    final LetterGatePack e = LetterGatePack('eng'), r = LetterGatePack('rus'), h = LetterGatePack('heb');
    // The documents are valid for the real validator, and the adapter reads them whole.
    for (final LetterGatePack p in <LetterGatePack>[e, r, h]) {
      expect(p.problems, isEmpty, reason: p.gateId);
    }
    eng = e.gate;
    rus = r.gate;
    heb = h.gate;
  });

  group('the gate documents', () {
    test('they read into the engine: age, durable age, the early set, the switch and the routes', () {
      expect(eng.minAge, 5);
      expect(eng.durableBelowAge, 7);
      expect(eng.early!.requires, engEarly.toSet());
      expect(eng.switchName, 'oralOnly');
      expect(eng.switchEffect, SwitchEffect.closes);
      expect(rus.minAge, 5);
      expect(rus.early!.requires, <String>{'RUS-A-12'});
      expect(rus.early!.requireAtLeast.single.count, 1);
      expect(rus.requireAtLeast.single.count, 3);
      expect(rus.switchEffect, SwitchEffect.opens);
      expect(rus.routeBypass, <String>{'heritage', 'reader'});
      expect(heb.minAge, 5);
      expect(heb.requires, isEmpty);
      expect(heb.early, isNull, reason: 'a Hebrew-speaking child has the words');
      expect(heb.holds, <String>{for (int n = 14; n <= 28; n++) 'HEB-B-$n'});
    });

    test('Hebrew A-10 to A-12 (print and the own name) are outside the gate', () {
      expect(heb.holds.intersection(<String>{'HEB-A-10', 'HEB-A-11', 'HEB-A-12'}), isEmpty);
    });

    test('the validator refuses an early set that asks for nothing, or names a skill the pack lacks', () {
      final LetterGatePack p = LetterGatePack('eng');
      (p.pack.doc('gate.eng.oral.json')['early']! as Map<String, Object?>)['requires'] = <String>[];
      expect(
        p.problems.where((Problem x) => x.path == 'gate.eng.oral.json › early'),
        isNotEmpty,
        reason: 'the early set is the words floor',
      );
      final LetterGatePack q = LetterGatePack('eng');
      (q.pack.doc('gate.eng.oral.json')['early']! as Map<String, Object?>)['requires'] = <String>['ENG-A-99'];
      expect(q.problems.map((Problem x) => x.message), contains(contains('ENG-A-99')));
    });

    test('a gate never reads the presentation band: the input has no such field, and the band of age changes nothing', () {
      for (final CourseGate g in <CourseGate>[eng, rus, heb]) {
        for (final int months in <int>[_m3, _m5, _m7]) {
          final GateResult r0 = gateResult(g, _in(months: months, band: 0));
          for (final int band in <int>[1, 2]) {
            expect(
              gateResult(g, _in(months: months, band: band)).open,
              r0.open,
              reason: '${g.id} $months',
            );
          }
        }
      }
    });
  });

  group('3;0 to 4;11: a beginner is served no letter skill in any course', () {
    test('the three gates are closed by age, whatever the skills (and Hebrew has none to ask)', () {
      final Map<String, MasteryLevel> eng_ = _all(_engCore, MasteryLevel.durable);
      final Map<String, MasteryLevel> rus_ = _all(<String>['RUS-A-12', ...rusThemes], MasteryLevel.durable);
      for (final int months in <int>[_m3, 48, _m4y11]) {
        final GateResult e = gateResult(eng, _in(months: months, mastery: eng_));
        expect(e.reasons, <GateReason>[GateReason.tooYoung], reason: 'eng $months');
        expect(gateResult(rus, _in(months: months, mastery: rus_)).reasons, <GateReason>[
          GateReason.tooYoung,
        ], reason: 'rus $months');
        expect(gateResult(heb, _in(months: months)).reasons, <GateReason>[
          GateReason.tooYoung,
        ], reason: 'heb $months');
      }
    });

    test(
      'so every letter skill of the three courses is held (and "together with words" does not reach under 6)',
      () {
        for (final (CourseGate g, Set<String> on) in <(CourseGate, Set<String>)>[
          (eng, <String>{lettersWithWordsSwitch}),
          (rus, <String>{lettersWithWordsSwitch}),
          (heb, <String>{}),
        ]) {
          final GateInput input = _in(months: _m4y11, band: 0, switchesOn: on);
          expect(heldSkills(<CourseGate>[g], input), g.holds, reason: g.id);
        }
      },
    );

    test('with no birth month the age bracket decides: Band A age (3 to 4) is held in all three', () {
      for (final CourseGate g in <CourseGate>[eng, rus, heb]) {
        expect(gateResult(g, _in(band: 0)).reasons, contains(GateReason.tooYoung), reason: g.id);
      }
    });
  });

  group('Hebrew letters open at 5;0', () {
    test('closed at 4;11, open at 5;0, with no skill asked', () {
      expect(gateResult(heb, _in(months: _m4y11)).open, isFalse);
      expect(gateResult(heb, _in(months: _m5)).open, isTrue);
      expect(heldSkills(<CourseGate>[heb], _in(months: _m5)), isEmpty);
    });

    test('by the bracket when no month is known: 5 to 6 and 7 to 8 are open', () {
      expect(gateResult(heb, _in(band: 1)).open, isTrue);
      expect(gateResult(heb, _in(band: 2)).open, isTrue);
    });
  });

  group('English: the oral gate gains age 5', () {
    final Map<String, MasteryLevel> fresh = _all(_engCore, MasteryLevel.fresh);
    final Map<String, MasteryLevel> durable = _all(_engCore, MasteryLevel.durable);

    test('a child who has the whole listening core is still held under 5', () {
      expect(gateResult(eng, _in(months: _m4y11, mastery: durable)).reasons, <GateReason>[
        GateReason.tooYoung,
      ]);
    });

    test('from 5 to 6 it needs durable mastery of the core; from 7 fresh is enough', () {
      expect(gateResult(eng, _in(months: _m5, mastery: durable)).open, isTrue);
      expect(gateResult(eng, _in(months: _m5, mastery: fresh)).open, isFalse);
      expect(gateResult(eng, _in(months: _m6y11, mastery: fresh)).open, isFalse);
      expect(gateResult(eng, _in(months: _m7, mastery: fresh)).open, isTrue);
    });

    test('the parent\'s "oral only" keeps it closed whatever else is on', () {
      final GateInput all = _in(
        months: _m7,
        mastery: durable,
        switchesOn: <String>{'oralOnly', lettersWithWordsSwitch},
        placedOpen: <String>{'eng.oral'},
        known: _engCore.toSet(),
      );
      expect(gateResult(eng, all).reasons, <GateReason>[GateReason.parentHolds]);
    });
  });

  group('Russian: as today (A-12, three themes, age 5)', () {
    final Map<String, MasteryLevel> three = _all(<String>[
      'RUS-A-12',
      ...rusThemes.take(3),
    ], MasteryLevel.fresh);

    test('A-12 and three themes, at 5;0', () {
      expect(gateResult(rus, _in(months: _m5, mastery: three)).open, isTrue);
      final GateResult two = gateResult(
        rus,
        _in(months: _m5, mastery: _all(<String>['RUS-A-12', ...rusThemes.take(2)], MasteryLevel.fresh)),
      );
      expect(two.reasons, <GateReason>[GateReason.skillsMissing]);
      expect(gateResult(rus, _in(months: _m4y11, mastery: three)).reasons, <GateReason>[GateReason.tooYoung]);
    });

    test('the heritage and reader routes keep the age bypass (the skills still count)', () {
      for (final String route in <String>['heritage', 'reader']) {
        expect(
          gateResult(rus, _in(months: _m3, mastery: three, route: route)).open,
          isTrue,
          reason: route,
        );
        expect(gateResult(rus, _in(months: _m3, route: route)).reasons, <GateReason>[
          GateReason.skillsMissing,
        ], reason: route);
      }
      expect(gateResult(rus, _in(months: _m3, mastery: three, route: 'new')).open, isFalse);
    });
  });

  group(
    'level comes before age: a child who knows letters is served them at any age, from the placed level',
    () {
      final Set<String> engEarlyKnown = engEarly.toSet();
      final Set<String> rusEarlyKnown = <String>{'RUS-A-12', rusThemes.first};

      test(
        'a 3-year-old placed open with the early set known has English, Russian and Hebrew letters open',
        () {
          expect(
            gateResult(eng, _in(months: _m3, placedOpen: <String>{'eng.oral'}, known: engEarlyKnown)).open,
            isTrue,
          );
          expect(
            gateResult(rus, _in(months: _m3, placedOpen: <String>{'rus.letters'}, known: rusEarlyKnown)).open,
            isTrue,
          );
          expect(gateResult(heb, _in(months: _m3, placedOpen: <String>{'heb.letters'})).open, isTrue);
          expect(
            heldSkills(<CourseGate>[heb], _in(months: _m3, placedOpen: <String>{'heb.letters'})),
            isEmpty,
          );
        },
      );

      test('placement only opens a gate and never closes one: no placement, the default stands', () {
        expect(gateResult(heb, _in(months: _m5)).open, isTrue);
        expect(gateResult(eng, _in(months: _m5, mastery: _all(_engCore, MasteryLevel.durable))).open, isTrue);
        expect(
          gateResult(heb, _in(months: _m3)).open,
          isFalse,
          reason: 'and without it a 3-year-old is held',
        );
      });

      test('a level-opened child who has met none of the words meets the early set first: never letters before any words', () {
        final GateResult e = gateResult(eng, _in(months: _m3, placedOpen: <String>{'eng.oral'}));
        expect(e.open, isFalse);
        expect(e.reasons, <GateReason>[GateReason.noWordsYet]);
        expect(e.missing, engEarly);
        final GateResult one = gateResult(
          eng,
          _in(
            months: _m3,
            placedOpen: <String>{'eng.oral'},
            known: engEarlyKnown.difference(<String>{'ENG-A-09'}),
          ),
        );
        expect(one.missing, <String>['ENG-A-09'], reason: 'the whole early set, not most of it');
        final GateResult r = gateResult(
          rus,
          _in(months: _m3, placedOpen: <String>{'rus.letters'}, known: <String>{'RUS-A-12'}),
        );
        expect(r.reasons, <GateReason>[
          GateReason.noWordsYet,
        ], reason: 'A-12 alone is not "A-12 and one theme"');
        expect(r.missing, rusThemes);
      });

      test('so a 3-year-old placed open with no words is held, and the held skills are all of them', () {
        expect(heldSkills(<CourseGate>[eng], _in(months: _m3, placedOpen: <String>{'eng.oral'})), eng.holds);
      });

      test('the early set may be known by being taught or by placement assuming it (the engine says which skills are met)', () {
        final CourseHomeFixture f = CourseHomeFixture('eng');
        f.engine.assume(f.skills.take(2));
        expect(knownSkills(f.engine), containsAll(f.skills.take(2)));
        expect(
          knownSkills(f.engine),
          isNot(contains(f.skills.last)),
          reason: 'a skill nobody taught or assumed',
        );
      });

      test('the Russian "letters before 5" switch opens the age, but still asks the early set', () {
        final GateResult none = gateResult(rus, _in(months: _m3, switchesOn: <String>{'lettersBefore5'}));
        expect(none.reasons, <GateReason>[GateReason.noWordsYet]);
        expect(
          gateResult(
            rus,
            _in(months: _m3, switchesOn: <String>{'lettersBefore5'}, known: rusEarlyKnown),
          ).open,
          isTrue,
        );
      });
    },
  );

  group('"letters together with words": the gate asks only for the early set, and never opens before it', () {
    final Set<String> on = <String>{lettersWithWordsSwitch};

    test('English at 7;0: the early set, fresh, is enough; at 6;0 it needs durable; at 5;6 the switch does nothing', () {
      final Map<String, MasteryLevel> fresh = _all(engEarly, MasteryLevel.fresh);
      final Map<String, MasteryLevel> durable = _all(engEarly, MasteryLevel.durable);
      expect(gateResult(eng, _in(months: _m7, mastery: fresh, switchesOn: on)).open, isTrue);
      expect(gateResult(eng, _in(months: _m6, mastery: fresh, switchesOn: on)).open, isFalse);
      expect(gateResult(eng, _in(months: _m6, mastery: durable, switchesOn: on)).open, isTrue);
      final GateResult young = gateResult(eng, _in(months: _m5h, mastery: durable, switchesOn: on));
      expect(young.open, isFalse, reason: 'the switch is hidden under 6;0, so it asks nothing of the gate');
      expect(young.reasons, <GateReason>[GateReason.skillsMissing]);
    });

    test(
      'English: with the switch off the full oral core is asked, and one early skill missing keeps it closed',
      () {
        final Map<String, MasteryLevel> fresh = _all(engEarly, MasteryLevel.fresh);
        expect(gateResult(eng, _in(months: _m7, mastery: fresh)).open, isFalse);
        final Map<String, MasteryLevel> short = <String, MasteryLevel>{...fresh}..remove('ENG-A-09');
        final GateResult r = gateResult(eng, _in(months: _m7, mastery: short, switchesOn: on));
        expect(r.open, isFalse);
        expect(r.missing, <String>['ENG-A-09']);
      },
    );

    test('Russian at 6: A-12 and one theme open it; A-12 alone does not; three themes are not needed', () {
      expect(
        gateResult(
          rus,
          _in(
            months: _m6,
            mastery: _all(<String>['RUS-A-12', rusThemes[2]], MasteryLevel.fresh),
            switchesOn: on,
          ),
        ).open,
        isTrue,
      );
      final GateResult alone = gateResult(
        rus,
        _in(months: _m6, mastery: _all(<String>['RUS-A-12'], MasteryLevel.fresh), switchesOn: on),
      );
      expect(alone.open, isFalse);
      expect(alone.missing, rusThemes);
      expect(
        gateResult(
          rus,
          _in(months: _m6, mastery: _all(<String>['RUS-A-12', rusThemes[2]], MasteryLevel.fresh)),
        ).open,
        isFalse,
        reason: 'switched off, the three themes are asked',
      );
    });

    test('Hebrew has no such switch: a Hebrew gate ignores it', () {
      expect(gateResult(heb, _in(months: _m4y11, switchesOn: on)).open, isFalse);
    });

    test('a gate that has no words (no one met any) stays closed even with the switch, whatever the age', () {
      expect(gateResult(eng, _in(months: _m7 + 24, switchesOn: on)).open, isFalse);
      expect(gateResult(rus, _in(months: _m7 + 24, switchesOn: on)).open, isFalse);
    });
  });

  group('the switch: hidden under 6;0, shown from 6, on by default from 7, a choice stands', () {
    const LanguageSwitches none = LanguageSwitches(on: true);

    test('hidden under 6;0 by the month, and by the bracket when no month is known', () {
      expect(LanguageSwitches.lettersWithWordsShown(ageBand: 1, ageMonths: 71), isFalse);
      expect(LanguageSwitches.lettersWithWordsShown(ageBand: 1, ageMonths: 72), isTrue);
      expect(LanguageSwitches.lettersWithWordsShown(ageBand: 0), isFalse);
      expect(
        LanguageSwitches.lettersWithWordsShown(ageBand: 1),
        isFalse,
        reason: '5 to 6 may be 5; the bracket is read by its youngest age',
      );
      expect(LanguageSwitches.lettersWithWordsShown(ageBand: 2), isTrue);
    });

    test('off from 6;0 until the parent chooses, on from 7;0', () {
      expect(none.lettersWithWordsOn(ageBand: 1, ageMonths: 71), isFalse);
      expect(none.lettersWithWordsOn(ageBand: 1, ageMonths: _m6), isFalse);
      expect(none.lettersWithWordsOn(ageBand: 1, ageMonths: _m6y11), isFalse);
      expect(none.lettersWithWordsOn(ageBand: 2, ageMonths: _m7), isTrue);
      expect(none.lettersWithWordsOn(ageBand: 2), isTrue);
    });

    test('a parent\'s own choice stands, in either direction, from 6', () {
      const LanguageSwitches yes = LanguageSwitches(on: true, lettersWithWords: true);
      const LanguageSwitches no = LanguageSwitches(on: true, lettersWithWords: false);
      expect(yes.lettersWithWordsOn(ageBand: 1, ageMonths: _m6), isTrue);
      expect(no.lettersWithWordsOn(ageBand: 2, ageMonths: _m7 + 12), isFalse);
      expect(yes.lettersWithWordsOn(ageBand: 1, ageMonths: _m5h), isFalse, reason: 'never under 6;0');
    });

    test('the gates read it by name, resolved for the child\'s age', () {
      expect(none.gateSwitchesOn(ageBand: 2, ageMonths: _m7), contains(lettersWithWordsSwitch));
      expect(none.gateSwitchesOn(ageBand: 1, ageMonths: _m6), isNot(contains(lettersWithWordsSwitch)));
      expect(
        const LanguageSwitches(lettersWithWords: true).gateSwitchesOn(ageBand: 1, ageMonths: _m6),
        contains(lettersWithWordsSwitch),
      );
    });

    test(
      'one boolean per course, English and Russian only; stored only when chosen; a damaged value is dropped',
      () {
        for (final String course in <String>[Course.eng, Course.rus]) {
          final LanguageSwitches off = LanguageSwitches.fromJson(course, <String, Object?>{
            'lettersWithWords': false,
          });
          expect(off.lettersWithWords, isFalse);
          expect(off.toJson(), <String, Object?>{'lettersWithWords': false});
          final LanguageSwitches yes = LanguageSwitches.fromJson(course, <String, Object?>{
            'lettersWithWords': true,
          });
          expect(yes.toJson(), <String, Object?>{'lettersWithWords': true});
          expect(
            LanguageSwitches.fromJson(course, <String, Object?>{'lettersWithWords': 'yes'}).lettersWithWords,
            isNull,
          );
          expect(
            LanguageSwitches.fromJson(course, <String, Object?>{'lettersWithWords': 1}).lettersWithWords,
            isNull,
          );
          expect(
            const LanguageSwitches().toJson(),
            isEmpty,
            reason: 'the age decides until the parent chooses',
          );
          expect(yes.copyWith(clearLettersWithWords: true).lettersWithWords, isNull);
        }
        expect(
          LanguageSwitches.fromJson(Course.heb, <String, Object?>{'lettersWithWords': true}).lettersWithWords,
          isNull,
          reason: 'Hebrew has no such switch',
        );
      },
    );

    test('the settings document carries it inside the family\'s rules, per child and course', () {
      final FamilyLanguages f = const FamilyLanguages().withSwitches(
        'child-aaaa-0001',
        Course.rus,
        const LanguageSwitches(on: true, lettersWithWords: false),
      )!;
      expect(f.encode(), contains('"lettersWithWords":false'));
      expect(FamilyLanguages.decode(f.encode()).of('child-aaaa-0001', Course.rus).lettersWithWords, isFalse);
      expect(FamilyLanguages.decode(f.encode()).of('child-aaaa-0001', Course.eng).lettersWithWords, isNull);
    });
  });

  group('the parent says the child knows letters or reads', () {
    LanguageSwitches q(Map<String, String> a) => LanguageSwitches(on: true, questionnaire: a);

    test('English: the letters answer; Hebrew: its one question; Russian: letters or reads', () {
      expect(q(<String, String>{'knowsLetters': 'some'}).claimsLetters(Course.eng), isTrue);
      expect(q(<String, String>{'understands': 'most'}).claimsLetters(Course.eng), isFalse);
      expect(q(<String, String>{'knowsLetters': 'reads'}).claimsLetters(Course.heb), isTrue);
      expect(q(<String, String>{'knowsLetters': 'no'}).claimsLetters(Course.heb), isFalse);
      expect(q(<String, String>{'letters': 'some'}).claimsLetters(Course.rus), isTrue);
      expect(q(<String, String>{'reads': 'syllables'}).claimsLetters(Course.rus), isTrue);
      expect(
        q(<String, String>{'understands': 'most', 'speaks': 'sentences'}).claimsLetters(Course.rus),
        isFalse,
      );
      expect(const LanguageSwitches().claimsLetters(Course.eng), isFalse);
    });
  });

  group(
    'the placement confirms letters (a level from `opens.fromLevel` passed at 2/3, before the minus one)',
    () {
      // An English fixture: the oral strand `o` and the letters strand `l` (3 levels of 2 probes), which opens `eng.oral` from level 1.
      PackContent pack() {
        final LetterGatePack g = LetterGatePack('eng');
        final LangPack lp = LangPack('eng')..addPictures(const <String>['cat', 'dog', 'duck']);
        for (final String id in <String>[
          'o_0_1',
          'o_0_2',
          'l_0_1',
          'l_0_2',
          'l_1_1',
          'l_1_2',
          'l_2_1',
          'l_2_2',
        ]) {
          lp.addProbe(id);
        }
        lp.pack.addDocument('gate.eng.oral.json', 'gates', 'eng.oral', g.pack.doc('gate.eng.oral.json'));
        for (final String id in (engOralGate['requires']! as List<String>).followedBy(
          engOralGate['holds']! as List<String>,
        )) {
          if (!lp.pack.docs.containsKey('skill.$id.json')) {
            lp.pack.addDocument('skill.$id.json', 'skills', id, g.pack.doc('skill.$id.json'));
          }
        }
        lp.addPlacement(
          placementJson('eng', <Map<String, Object?>>[
            strandJson('o', 'eng', <List<String>>[
              <String>['o_0_1'],
              <String>['o_0_2'],
            ]),
            strandJson(
              'l',
              'eng',
              <List<String>>[
                <String>['l_0_1', 'l_0_2'],
                <String>['l_1_1', 'l_1_2'],
                <String>['l_2_1', 'l_2_2'],
              ],
              offer: <String, Object?>{'answer': 'knowsLetters', 'equals': 'some'},
              opens: <String, Object?>{'gate': 'eng.oral', 'fromLevel': 1},
            ),
          ]),
        );
        return PackContent.fromPack(lp.pack.verified());
      }

      PlacementStatus played(PackContent c, List<(String, bool)> answers) {
        final PlacementGame g = placementGameOf(c, answers: const <String, String>{'knowsLetters': 'some'})!;
        for (final (String id, bool right) in answers) {
          g.record('eng.$id', right: right);
        }
        return PlacementStatus.of(g);
      }

      const LanguageSwitches claims = LanguageSwitches(
        on: true,
        questionnaire: <String, String>{'knowsLetters': 'some'},
      );

      test('the document is valid: the strand names a gate of the pack and a level of its own', () {
        expect(pack().placement!.strands[1].opensGate, 'eng.oral');
        expect(pack().placement!.strands[1].opensFromLevel, 1);
        final LangPack bad = LangPack('eng');
        bad.addPlacement(
          placementJson('eng', <Map<String, Object?>>[
            strandJson(
              'l',
              'eng',
              <List<String>>[
                <String>['l_0_1'],
                <String>['l_1_1'],
              ],
              opens: <String, Object?>{'gate': 'eng.nowhere', 'fromLevel': 5},
            ),
          ]),
        );
        final List<String> said = <String>[
          for (final Problem x in validatePack(
            manifest: bad.pack.manifest,
            docs: bad.pack.docs,
            files: bad.pack.files,
          ))
            '${x.path}: ${x.message}',
        ];
        expect(said, contains(contains('there is no gate "eng.nowhere"')));
        expect(said, contains(contains('is not a level of the strand')));
      });

      test('right answers up to a level from `fromLevel` mark the gate open, when the parent says the child knows letters', () {
        final PackContent c = pack();
        final PlacementStatus all = played(c, <(String, bool)>[
          ('l_0_1', true),
          ('l_0_2', true),
          ('l_1_1', true),
          ('l_1_2', true),
          ('l_2_1', true),
          ('l_2_2', true),
        ]);
        expect(all.results['l']!.stopped, isTrue);
        expect(placedOpenGates(c, all, claims), <String>{'eng.oral'});
        expect(
          placedOpenGates(c, all, const LanguageSwitches(on: true)),
          isEmpty,
          reason: 'the parent did not say so',
        );
        expect(
          placedOpenGates(
            c,
            all,
            const LanguageSwitches(on: true, questionnaire: <String, String>{'understands': 'most'}),
          ),
          isEmpty,
          reason: 'knowing words is not knowing letters',
        );
      });

      test('a level below `fromLevel` does not confirm, and neither do misses at the floor; an unfinished strand places nobody', () {
        final PackContent c = pack();
        expect(
          placedOpenGates(
            c,
            played(c, <(String, bool)>[('l_0_1', true), ('l_0_2', true), ('l_1_1', false)]),
            claims,
          ),
          isEmpty,
          reason: 'only level 0 was passed: best 0 is below fromLevel 1',
        );
        expect(
          placedOpenGates(c, played(c, <(String, bool)>[('l_0_1', false), ('l_0_2', false)]), claims),
          isEmpty,
        );
        expect(
          placedOpenGates(
            c,
            played(c, <(String, bool)>[('l_0_1', true), ('l_0_2', true), ('l_1_1', true)]),
            claims,
          ),
          isEmpty,
          reason: 'the strand has not stopped yet',
        );
        expect(placedOpenGates(c, null, claims), isEmpty);
      });

      test('a pack with no strand that opens a gate marks none', () {
        final PackContent c = courseContent('eng');
        final PlacementGame g = placementGameOf(c, answers: const <String, String>{'knowsLetters': 'some'})!;
        expect(placedOpenGates(c, PlacementStatus.of(g), claims), isEmpty);
      });
    },
  );

  group('the course as the app builds it: lessons that teach a held skill are not offered, letters open only when the gate does', () {
    // The English course fixture with the oral gate: ENG-B-16 is letter work (it needs A-01), taught by one lesson, held until the
    // early set A-01, A-03, A-05 is met; the early set also gates a child placed open, and the plain gate wants the fourth skill too.
    PackContent withLetters() {
      final LangPack p = courseFixture('eng');
      // The fixture's skills have one representation and no check: a lighter bar for the early set, so four days of right answers reach it.
      for (final String id in <String>['ENG-A-01', 'ENG-A-03', 'ENG-A-05']) {
        p.pack.doc('skill.$id.json')['masteryRequires'] = <String, Object?>{
          'successes': 4,
          'days': 2,
          'representations': 1,
          'checks': 0,
        };
      }
      p.pack.addDocument('skill.ENG-B-16.json', 'skills', 'ENG-B-16', <String, Object?>{
        ...p.pack.doc('skill.ENG-A-03.json'),
        'id': 'ENG-B-16',
        'band': 'B',
        'letters': true,
      });
      p.pack.addDocument('lesson.eng.letters_1.json', 'lessons', 'eng.letters_1', <String, Object?>{
        ...p.pack.doc('lesson.eng.colours_1.json'),
        'id': 'eng.letters_1',
        'skills': <String>['ENG-B-16'],
        'sequence': 99,
      });
      p.pack.addDocument('gate.eng.oral.json', 'gates', 'eng.oral', <String, Object?>{
        'schema': 'gate/v1',
        'id': 'eng.oral',
        'course': 'eng',
        'requires': <String>['ENG-A-01', 'ENG-A-03', 'ENG-A-05', 'ENG-A-06'],
        'holds': <String>['ENG-B-16'],
        'minAge': 5,
        'durableBelowAge': 7,
        'early': <String, Object?>{
          'requires': <String>['ENG-A-01', 'ENG-A-03', 'ENG-A-05'],
        },
        'parentSwitch': <String, Object?>{'name': 'oralOnly', 'effect': 'closes'},
      });
      return PackContent.fromPack(p.pack.verified());
    }

    LanguageCourse course(LanguageSwitches s, {required int band, int? months}) =>
        languageCourseOf(withLetters(), const <Attempt>[], s, band, ageMonths: months);

    test('a 3-year-old beginner: the letter skill is held, its lesson is held, and the course home never offers it', () {
      final LanguageCourse c = course(const LanguageSwitches(on: true), band: 0, months: _m3);
      expect(c.held, <String>{'ENG-B-16'});
      expect(c.lettersOpen, isFalse);
      expect(c.heldLessons, <String>{'eng.letters_1'});
      final CourseHomeModel home = buildCourseHome(
        course: c,
        attempts: const <Attempt>[],
        sessions: const <Session>[],
        rewardKeys: const <String>[],
        now: DateTime.utc(2026, 11, 14, 9),
        band: 0,
      );
      expect(home.next!.lessonId, isNot('eng.letters_1'));
      expect(home.stop.lessonId, isNot('eng.letters_1'));
      expect(home.stones.map((PathStone s) => s.state), everyElement(isNot(StoneState.done)));
    });

    // Level first, through the whole chain the app uses: the parent's answer, the placement answers as rows, the assumed skills, the gate.
    PackContent withLevelLetters() {
      final LangPack p = courseFixture('eng');
      p.pack.addDocument('skill.ENG-B-16.json', 'skills', 'ENG-B-16', <String, Object?>{
        ...p.pack.doc('skill.ENG-A-03.json'),
        'id': 'ENG-B-16',
        'band': 'B',
        'letters': true,
      });
      p.pack.addDocument('gate.eng.oral.json', 'gates', 'eng.oral', <String, Object?>{
        'schema': 'gate/v1',
        'id': 'eng.oral',
        'course': 'eng',
        'requires': <String>['ENG-A-01', 'ENG-A-03', 'ENG-A-05', 'ENG-A-06'],
        'holds': <String>['ENG-B-16'],
        'minAge': 5,
        'early': <String, Object?>{
          'requires': <String>['ENG-A-01', 'ENG-A-03'],
        },
      });
      // The fixture's one strand stands in for a letters strand: passing its level 3 confirms letters.
      final Map<String, Object?> strand =
          ((p.pack.doc('placement.eng.placement.json')['strands']! as List<Object?>).first)!
              as Map<String, Object?>;
      strand['opens'] = <String, Object?>{'gate': 'eng.oral', 'fromLevel': 3};
      return PackContent.fromPack(p.pack.verified());
    }

    List<Attempt> placementRows(PackContent pack, List<(String, bool)> answers) => <Attempt>[
      for (final (int i, (String, bool) a) in answers.indexed)
        attemptRow(
          pack,
          a.$1,
          result: a.$2 ? 'correct' : 'incorrect',
          lessonId: placementIdFor('eng'),
          at: DateTime.utc(2026, 11, 3, 9).add(Duration(minutes: i)),
          id: i + 1,
        ),
    ];

    const LanguageSwitches knowsLetters = LanguageSwitches(
      on: true,
      questionnaire: <String, String>{'knowsLetters': 'some'},
    );

    test('a 3-year-old whose parent says they know letters and whose placement confirms it is served them: held nothing, letters open', () {
      final PackContent pack = withLevelLetters();
      final List<Attempt> rows = placementRows(pack, <(String, bool)>[
        ('pr_col_1', true),
        ('pr_col_2', true),
        ('pr_ani_1', true),
        ('pr_ani_2', true),
        ('pr_body_1', true),
        ('pr_body_2', true),
      ]);
      final LanguageCourse c = languageCourseOf(pack, rows, knowsLetters, 0, ageMonths: _m3);
      expect(c.placement!.results['o']!.best, 3);
      expect(c.assumed, containsAll(<String>['ENG-A-01', 'ENG-A-03']));
      expect(c.held, isEmpty, reason: 'level before age: the letters are served from the placed level');
      expect(c.lettersOpen, isTrue);
      expect(c.heldLessons, isEmpty);
    });

    test('the same child whose placement does not confirm letters keeps the default: held (and the parent can ask again)', () {
      final PackContent pack = withLevelLetters();
      final List<Attempt> rows = placementRows(pack, <(String, bool)>[
        ('pr_col_1', true),
        ('pr_col_2', true),
        ('pr_ani_1', false),
        ('pr_col_1', false),
      ]);
      final LanguageCourse c = languageCourseOf(pack, rows, knowsLetters, 0, ageMonths: _m3);
      expect(c.held, <String>{'ENG-B-16'});
      expect(c.lettersOpen, isFalse);
    });

    test('a child whose parent did not say they know letters is not opened by the placement alone', () {
      final PackContent pack = withLevelLetters();
      final List<Attempt> rows = placementRows(pack, <(String, bool)>[
        ('pr_hello_1', true),
        ('pr_hello_2', true),
        ('pr_col_1', true),
        ('pr_col_2', true),
        ('pr_ani_1', true),
        ('pr_ani_2', true),
        ('pr_body_1', true),
        ('pr_body_2', true),
      ]);
      final LanguageCourse c = languageCourseOf(
        pack,
        rows,
        const LanguageSwitches(on: true, placementAsked: true),
        0,
        ageMonths: _m3,
      );
      expect(c.held, <String>{'ENG-B-16'});
    });

    test('a 5-year-old beginner (no words met yet) is held too: the age is not the only condition', () {
      final LanguageCourse c = course(const LanguageSwitches(on: true), band: 1, months: _m5);
      expect(c.held, <String>{'ENG-B-16'});
      expect(c.lettersOpen, isFalse);
    });

    test('a 3-year-old whose parent says they know letters but who has met no words is held (the early set comes first)', () {
      final LanguageCourse c = course(
        const LanguageSwitches(on: true, questionnaire: <String, String>{'knowsLetters': 'some'}),
        band: 0,
        months: _m3,
      );
      expect(c.held, <String>{'ENG-B-16'});
      expect(c.lettersOpen, isFalse);
    });

    test('the gates are read from the live engine: once the early set is learned, a 7-year-old with "together with words" is served letters', () {
      final PackContent content = withLetters();
      final LanguageCourse c = languageCourseOf(
        content,
        const <Attempt>[],
        const LanguageSwitches(on: true, lettersWithWords: true),
        2,
        ageMonths: _m7,
      );
      expect(c.held, <String>{'ENG-B-16'});
      expect(c.heldLessons, <String>{'eng.letters_1'});
      // Four days of right answers on every item of the early set (A-01, A-03, A-05), on the engine the course already holds.
      int n = 0;
      for (int day = 0; day < 4; day++) {
        for (final ItemMeta item in c.engine.catalog.items.values) {
          if (!<String>{'ENG-A-01', 'ENG-A-03', 'ENG-A-05'}.contains(item.primarySkill)) continue;
          c.engine.apply(
            AttemptEvent(
              id: ++n,
              at: DateTime.utc(2026, 11, 2, 9).add(Duration(days: day, minutes: n)),
              activityId: item.id,
              result: Result.correct,
              sessionId: day + 1,
            ),
          );
        }
      }
      expect(c.held, isEmpty, reason: 'the same LanguageCourse, read again: nothing is a stale copy');
      expect(c.lettersOpen, isTrue);
      expect(c.heldLessons, isEmpty);
    });

    test(
      'a gate that holds no letter skill (the Russian sounds gate) holds no lesson: the path is as before',
      () {
        final LangPack p = courseFixture('rus');
        p.pack.addDocument('gate.rus.sounds.json', 'gates', 'rus.sounds', <String, Object?>{
          'schema': 'gate/v1',
          'id': 'rus.sounds',
          'course': 'rus',
          'requires': <String>['RUS-A-05'],
          'holds': <String>['RUS-A-19'],
          'routeBypass': <String>['heritage', 'reader'],
        });
        final PackContent content = PackContent.fromPack(p.pack.verified());
        final LanguageCourse c = languageCourseOf(
          content,
          const <Attempt>[],
          const LanguageSwitches(on: true),
          0,
        );
        expect(courseGates(content).single.holds, <String>{'RUS-A-19'});
        expect(c.held, isEmpty);
        expect(c.heldLessons, isEmpty);
        expect(c.lettersOpen, isFalse);
      },
    );

    test('"oral only" closes it for a child of any age or level', () {
      final LanguageCourse c = course(const LanguageSwitches(on: true, oralOnly: true), band: 2, months: _m7);
      expect(c.held, <String>{'ENG-B-16'});
    });

    test(
      'a course whose pack has no letters gate holds nothing and has no letters open (nothing is printed)',
      () {
        final LanguageCourse c = languageCourseOf(
          courseContent('eng'),
          const <Attempt>[],
          const LanguageSwitches(on: true),
          2,
          ageMonths: _m7,
        );
        expect(c.held, isEmpty);
        expect(c.lettersOpen, isFalse);
        expect(heldLessonIds(courseContent('eng'), const <String>{}), isEmpty);
      },
    );

    test('courseGateState names what is held and whether letters are open, from the engine and the age', () {
      final PackContent content = withLetters();
      final LanguageCourse base = languageCourseOf(
        content,
        const <Attempt>[],
        const LanguageSwitches(on: true),
        2,
        ageMonths: _m7,
      );
      final ({Set<String> held, bool lettersOpen}) s = courseGateState(
        content: content,
        engine: base.engine,
        context: const GateContext(switches: LanguageSwitches(on: true), ageBand: 2, ageMonths: _m7),
      );
      expect(s.held, <String>{'ENG-B-16'});
      expect(s.lettersOpen, isFalse);
    });
  });

  group('the Meet screen follows the gate: a word is printed only when the letters are open', () {
    // The Hebrew letters gate needs no skill, only age 5: a 5-year-old's letters are open, a 3-year-old's are not.
    LanguageCourse made({required bool open}) {
      final PackContent content = LetterGatePack('heb').content;
      return LanguageCourse(
        content: content,
        engine: Engine(catalog: engineCatalog(content)),
        gateContext: GateContext(ageBand: open ? 1 : 0, ageMonths: open ? _m5 : _m3),
      );
    }

    Future<bool Function(String, String)> provider(List<LanguageCourse> courses) async {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[languageCoursesProvider('kid-1').overrideWith((Ref ref) async => courses)],
      );
      addTearDown(c.dispose);
      await c.read(languageCoursesProvider('kid-1').future);
      return c.read(meetLettersOpenProvider);
    }

    test('open when the course says so, closed otherwise, and closed for another course or child', () async {
      expect((await provider(<LanguageCourse>[made(open: true)]))('kid-1', 'heb'), isTrue);
      expect((await provider(<LanguageCourse>[made(open: false)]))('kid-1', 'heb'), isFalse);
      expect((await provider(<LanguageCourse>[made(open: true)]))('kid-1', 'rus'), isFalse);
      expect((await provider(<LanguageCourse>[made(open: true)]))('kid-2', 'heb'), isFalse);
    });

    test('closed while the courses are not read yet', () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(meetLettersOpenProvider)('kid-1', 'eng'), isFalse);
    });
  });
}

/// An English fixture course and its engine, for the tests that ask what the engine counts as known.
class CourseHomeFixture {
  CourseHomeFixture(String course) : content = courseContent(course) {
    engine = Engine(catalog: engineCatalog(content));
  }

  final PackContent content;
  late final Engine engine;

  List<String> get skills => content.skills.keys.toList()..sort();
}
