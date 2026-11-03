// The parent's settings for each language of each child (docs/languages/frame.md section 1.4): the defaults, what is stored, how
// a damaged value is read, that the app and the gateway agree (testvectors/language-settings.json), and that the settings
// are synced inside the family's rules like the other per-child settings and go with the child.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/parent/language_settings.dart';

const String kid = 'child-aaaa-0001';
const String kid2 = 'child-aaaa-0002';

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;

void main() {
  final Map<String, Object?> vector =
      jsonDecode(File('../testvectors/language-settings.json').readAsStringSync()) as Map<String, Object?>;

  group('the defaults: nothing is on until a parent turns it on', () {
    test('a language that was never touched is off, with the voice off and personal questions on', () {
      const FamilyLanguages none = FamilyLanguages();
      for (final String c in Course.languages) {
        final LanguageSwitches s = none.of(kid, c);
        expect(s.on, isFalse, reason: c);
        expect(s.voice, isFalse);
        expect(s.personal, isTrue);
        expect(s.oralOnly, isFalse);
        expect(s.lettersBefore5, isFalse);
        expect(s.stress, StressMarks.route);
        expect(s.readCheck, isFalse);
        expect(s.route, isNull);
        expect(s.band, isNull);
        expect(s.questionnaire, isEmpty);
        expect(s.isDefault, isTrue);
      }
      expect(none.enabledFor(kid), isEmpty);
      expect(none.isEmpty, isTrue);
      expect(none.encode(), '{}');
    });

    test('only what differs from the default is written', () {
      expect(const LanguageSwitches().toJson(), isEmpty);
      expect(const LanguageSwitches(on: true).toJson(), <String, Object?>{'on': true});
      expect(const LanguageSwitches(personal: false, band: 0).toJson(), <String, Object?>{
        'personal': false,
        'band': 0,
      });
      expect(const LanguageSwitches(personal: true, voice: false).toJson(), isEmpty);
    });
  });

  group('turning a language on and off', () {
    test('on shows in the list of the courses that are on, in the order of the doors', () {
      FamilyLanguages f = const FamilyLanguages();
      f = f.withSwitches(kid, 'rus', const LanguageSwitches(on: true))!;
      f = f.withSwitches(kid, 'eng', const LanguageSwitches(on: true))!;
      expect(f.enabledFor(kid), <String>['eng', 'rus']);
      expect(f.enabledFor(kid2), isEmpty, reason: 'another child has nothing');
    });

    test(
      'turning a language off keeps everything else the parent chose, and turning it on again resumes',
      () {
        FamilyLanguages f = const FamilyLanguages();
        const LanguageSwitches chosen = LanguageSwitches(
          on: true,
          voice: true,
          route: 'heritage',
          band: 1,
          questionnaire: <String, String>{'home': 'bothParents'},
        );
        f = f.withSwitches(kid, 'rus', chosen)!;
        f = f.withSwitches(kid, 'rus', f.of(kid, 'rus').copyWith(on: false))!;
        expect(f.enabledFor(kid), isEmpty);
        expect(f.of(kid, 'rus').route, 'heritage');
        expect(f.of(kid, 'rus').questionnaire, <String, String>{'home': 'bothParents'});
        f = f.withSwitches(kid, 'rus', f.of(kid, 'rus').copyWith(on: true))!;
        expect(f.of(kid, 'rus'), chosen);
      },
    );

    test('turning a language off changes nothing in another language, or in another child', () {
      FamilyLanguages f = const FamilyLanguages();
      f = f.withSwitches(kid, 'eng', const LanguageSwitches(on: true, oralOnly: true))!;
      f = f.withSwitches(kid, 'heb', const LanguageSwitches(on: true, readCheck: true))!;
      f = f.withSwitches(kid2, 'eng', const LanguageSwitches(on: true))!;
      final String before = f.encode();
      final FamilyLanguages g = f.withSwitches(kid, 'heb', f.of(kid, 'heb').copyWith(on: false))!;
      expect(g.of(kid, 'eng'), f.of(kid, 'eng'));
      expect(g.of(kid2, 'eng'), f.of(kid2, 'eng'));
      expect(f.encode(), before, reason: 'the old value was not changed in place');
    });

    test('a language put back to the defaults leaves nothing behind, and a child with nothing is gone', () {
      FamilyLanguages f = const FamilyLanguages();
      f = f.withSwitches(kid, 'eng', const LanguageSwitches(on: true))!;
      f = f.withSwitches(kid, 'eng', const LanguageSwitches())!;
      expect(f.isEmpty, isTrue);
      expect(f.encode(), '{}');
    });

    test('the switches of one course cannot be set on another', () {
      FamilyLanguages f = const FamilyLanguages();
      f = f.withSwitches(
        kid,
        'eng',
        const LanguageSwitches(on: true, lettersBefore5: true, readCheck: true),
      )!;
      expect(f.of(kid, 'eng').lettersBefore5, isFalse);
      expect(f.of(kid, 'eng').readCheck, isFalse);
      f = f.withSwitches(kid, 'rus', const LanguageSwitches(on: true, oralOnly: true))!;
      expect(f.of(kid, 'rus').oralOnly, isFalse);
      f = f.withSwitches(
        kid,
        'heb',
        const LanguageSwitches(on: true, route: 'heritage', stress: StressMarks.on),
      )!;
      expect(f.of(kid, 'heb').route, isNull);
      expect(f.of(kid, 'heb').stress, StressMarks.route);
    });

    test('a course that is not a language, and an id that is not a child\'s, are refused', () {
      const FamilyLanguages f = FamilyLanguages();
      expect(f.withSwitches(kid, 'core', const LanguageSwitches(on: true)), isNull);
      expect(f.withSwitches(kid, 'fra', const LanguageSwitches(on: true)), isNull);
      expect(f.withSwitches('x', 'eng', const LanguageSwitches(on: true)), isNull);
      expect(f.withSwitches('has space in it', 'eng', const LanguageSwitches(on: true)), isNull);
    });

    test('only so many children have language settings (the rules document has room for no more)', () {
      FamilyLanguages f = const FamilyLanguages();
      for (int i = 1; i <= maxLanguageChildren; i++) {
        f = f.withSwitches('child-zzzz-000$i', 'eng', const LanguageSwitches(on: true))!;
      }
      expect(f.withSwitches('child-zzzz-0009', 'eng', const LanguageSwitches(on: true)), isNull);
      expect(f.withSwitches('child-zzzz-0001', 'heb', const LanguageSwitches(on: true)), isNotNull);
      expect(
        f.withSwitches('child-zzzz-0009', 'eng', const LanguageSwitches()),
        isNotNull,
        reason: 'nothing to add',
      );
      expect(
        f.without('child-zzzz-0001').withSwitches('child-zzzz-0009', 'eng', const LanguageSwitches(on: true)),
        isNotNull,
      );
    });
  });

  group('what the gates and the pace read', () {
    test('the parent switches a gate may name, and the presentation band for the course', () {
      const LanguageSwitches s = LanguageSwitches(on: true, oralOnly: true, lettersBefore5: true, band: 0);
      expect(s.gateSwitchesOn, <String>{'oralOnly', 'lettersBefore5'});
      expect(const LanguageSwitches(on: true).gateSwitchesOn, isEmpty);
      expect(s.presentationBand(2), 0, reason: 'the parent\'s choice wins');
      expect(const LanguageSwitches(on: true).presentationBand(2), 2, reason: 'otherwise the age decides');
    });
  });

  group('a damaged or hand-made document is read safely', () {
    test('anything that is not in the table is dropped, never turned into something else', () {
      final FamilyLanguages f = FamilyLanguages.fromJson(<String, Object?>{
        kid: <String, Object?>{
          'eng': <String, Object?>{
            'on': 'yes',
            'voice': 1,
            'band': 7,
            'name': 'Noa',
            'oralOnly': true,
            'q': <String, Object?>{'knowsLetters': 'all', 'home': 'none'},
          },
          'fra': <String, Object?>{'on': true},
          'rus': 'on',
        },
        'short': <String, Object?>{
          'eng': <String, Object?>{'on': true},
        },
        kid2: 7,
      });
      expect(f.enabledFor(kid), isEmpty);
      expect(f.of(kid, 'eng').oralOnly, isTrue, reason: 'the one valid thing in it');
      expect(f.of(kid, 'eng').band, isNull);
      expect(f.of(kid, 'eng').questionnaire, isEmpty);
      expect(f.of('short', 'eng').on, isFalse);
      expect(f.toJson().keys, <String>[kid]);
    });

    test('text that is not JSON, or not an object, is no settings at all', () {
      for (final String? text in <String?>[null, '', 'not json', '[1]', '"eng"', '7', 'null']) {
        expect(FamilyLanguages.decode(text).isEmpty, isTrue, reason: '$text');
      }
    });

    test('the questionnaire takes the answers of its own course and nothing else', () {
      final LanguageSwitches s = LanguageSwitches.fromJson('rus', <String, Object?>{
        'q': <String, Object?>{
          'home': 'grandparentsOthers',
          'understands': 'most',
          'speaks': 'sentences',
          'letters': 'some',
          'reads': 'words',
          'knowsLetters': 'some',
          'address': 'Haifa',
        },
      });
      expect(s.questionnaire.keys, <String>['home', 'understands', 'speaks', 'letters', 'reads']);
    });
  });

  group('the app and the gateway agree (testvectors/language-settings.json)', () {
    test('the table of switches, the questionnaire and the limits', () {
      expect(maxLanguageChildren, vector['max_children']);
      expect(Course.languages, vector['courses']);
      final Map<String, Object?> table = _m(vector['switches']);
      // Every switch of the table can be written, and only for the courses the table names.
      for (final MapEntry<String, Object?> e in table.entries) {
        final List<Object?> courses = _m(e.value)['courses']! as List<Object?>;
        final Set<String> own = <String>{
          for (final MapEntry<String, Set<String>> o in languageOwnSwitches.entries)
            if (o.value.contains(e.key)) o.key,
        };
        final bool forAll = courses.length == Course.languages.length;
        expect(forAll ? own.isEmpty : own.toSet().containsAll(courses.cast<String>()), isTrue, reason: e.key);
        if (!forAll) expect(own, courses.toSet(), reason: e.key);
      }
      expect(
        languageQuestionnaire,
        _m(vector['questionnaire']).map((String k, Object? v) {
          return MapEntry<String, Map<String, List<String>>>(
            k,
            _m(v).map(
              (String q, Object? a) =>
                  MapEntry<String, List<String>>(q, (a! as List<Object?>).cast<String>()),
            ),
          );
        }),
      );
    });

    test(
      'every example is read and written again unchanged (the app writes exactly what the gateway takes)',
      () {
        for (final Object? example in vector['examples']! as List<Object?>) {
          expect(jsonDecode(FamilyLanguages.fromJson(example).encode()), example);
        }
      },
    );

    test('everything the gateway refuses is cut down to something it takes, or to nothing', () {
      for (final Object? doc in vector['refused']! as List<Object?>) {
        final FamilyLanguages f = FamilyLanguages.fromJson(doc);
        // Read again, it is stable (nothing odd survives a second reading).
        expect(FamilyLanguages.fromJson(f.toJson()).encode(), f.encode(), reason: jsonEncode(doc));
        for (final MapEntry<String, Object?> child in f.toJson().entries) {
          for (final MapEntry<String, Object?> course in _m(child.value).entries) {
            expect(Course.languages, contains(course.key));
            for (final String key in _m(course.value).keys) {
              expect(<String>{..._m(vector['switches']).keys, 'q'}, contains(key));
            }
          }
        }
      }
    });
  });

  group('a child that is deleted takes the language settings with it', () {
    test('the settings of that child go, the others stay', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final FamilyLanguages f = const FamilyLanguages()
          .withSwitches(kid, 'eng', const LanguageSwitches(on: true))!
          .withSwitches(kid2, 'rus', const LanguageSwitches(on: true))!;
      await db.putSetting(languagesSettingKey, f.encode());
      await db.deleteChildData(kid);
      final FamilyLanguages after = FamilyLanguages.decode(await db.setting(languagesSettingKey));
      expect(after.enabledFor(kid), isEmpty);
      expect(after.enabledFor(kid2), <String>['rus']);
    });
  });
}
