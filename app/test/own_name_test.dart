// The own-name items of Hebrew Band A (HEB-A-11, tap_answer 1.5, `answer.type` `name`): the options are made on the device when a lesson opens,
// from the child's first name, by the rules NAME-FIRST (the same first letter) and NAME-LENGTH (the same number of letters), out of a closed
// list of names. The name is never in a pack, a log, a row or a message: an answer is recorded as the id of the option. Decision 25 of
// 2026-11-03 (docs/languages/decisions-2026-11-03.md); the security-engineer reviews it.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/name_options.dart';
import 'package:nitznutz/play/response_code.dart';
import 'package:nitznutz/tutor/tutor.dart' show TutorAttempt;

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_golden.dart' show boards, waitFor;
import 'support/language_screens.dart' show langKid;
import 'support/language_voice.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const String _languages = '../content/languages';
final RegExp _hebrewLetter = RegExp(r'[א-ת]');

void main() {
  late PackContent heb;
  late VerifiedPack pack;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    final PackKey key = await newTestKey();
    pack = await verifyPack(
      (await buildPack(languageSource('heb', _languages), key)).bytes,
      publicKey: key.publicKey,
    );
    heb = PackContent.fromPack(pack);
  });

  TapAnswerActivity item(String id) => heb.activities['heb.a11.$id']! as TapAnswerActivity;

  /// The texts of an item once its options are made, by option id.
  Map<String, String> texts(Activity a) => <String, String>{
    for (final ChoiceOption o in (a as TapAnswerActivity).options) o.id: o.text!,
  };

  List<String> closedList() =>
      (((heb.activities['heb.a11.02']!.json['answer']! as Map<String, Object?>)['names']!) as List<Object?>)
          .cast<String>();

  group('the name as it is printed', () {
    test('a pointed name loses its nikud, and only the first name is taken', () {
      expect(printName('נֹעָה'), 'נעה');
      expect(printName('  דָּנִי   כֹּהֵן '), 'דני');
      expect(printName('בן-ציון'), 'בן');
    });

    test('a name that is not two to eight Hebrew letters is passed over', () {
      for (final String? raw in <String?>[
        null,
        '',
        '   ',
        'Noa',
        'נ',
        'אבגדהוזחטי',
        "ג'ו",
        'דני2',
        '‏נועה‏',
      ]) {
        // the direction marks of a pasted name are cleaned away by the one rule for names; everything else is refused
        if (raw == '‏נועה‏') {
          expect(printName(raw), 'נועה');
        } else {
          expect(printName(raw), isNull, reason: '$raw');
        }
      }
    });
  });

  group('a choice of names (A-11.2)', () {
    test(
      'the child\'s name, a name of the same first letter, a name of the same length, all from the list',
      () {
        final List<String> list = closedList();
        for (int seed = 0; seed < 40; seed++) {
          final Activity made = OwnName(childName: 'דנה', random: math.Random(seed)).apply(item('02'));
          final Map<String, String> t = texts(made);
          expect(t.length, 3);
          final String own = t.values.firstWhere((String s) => !list.contains(s) || s == 'דנה');
          expect(t.values, contains('דנה'));
          final Iterable<String> others = t.values.where((String s) => s != 'דנה');
          for (final String n in others) {
            expect(list, contains(n), reason: 'a distractor is a name of the closed list, never made up');
          }
          // NAME-FIRST: the first letter of the name; NAME-LENGTH: as many letters, another first letter; never the child's name
          final TapAnswerActivity a = made as TapAnswerActivity;
          final String first = a.options
              .firstWhere((ChoiceOption o) => o.misconception == 'heb.pk.name_first')
              .text!;
          final String length = a.options
              .firstWhere((ChoiceOption o) => o.misconception == 'heb.pk.name_length')
              .text!;
          expect(first[0], own[0]);
          expect(first, isNot(own));
          expect(length.length, own.length);
          expect(length[0], isNot(own[0]));
          expect(length, isNot(first));
        }
      },
    );

    test(
      'the right option is the child\'s name and carries no tag; a distractor carries the tag of its rule',
      () {
        final TapAnswerActivity a = OwnName(childName: 'יעל').apply(item('02')) as TapAnswerActivity;
        expect(a.ownName, isFalse, reason: 'once made it is an ordinary choice of texts');
        final ChoiceOption right = a.options.firstWhere((ChoiceOption o) => o.id == a.correctId);
        expect(right.text, 'יעל');
        expect(right.misconception, isNull);
        expect(
          <String?>{for (final ChoiceOption o in a.options) o.misconception},
          <String?>{null, 'heb.pk.name_first', 'heb.pk.name_length'},
        );
        expect(a.letterFace, isFalse, reason: 'names are words on a tile, letters are not');
      },
    );

    test('the guided step has two names: the child\'s and a name of the same length', () {
      final TapAnswerActivity a = OwnName(childName: 'גיל').apply(item('01')) as TapAnswerActivity;
      expect(a.options.length, 2);
      expect(a.maxAttempts, 2, reason: 'a two-choice item allows one retry');
      final ChoiceOption other = a.options.firstWhere((ChoiceOption o) => o.id != a.correctId);
      expect(other.text!.length, 3);
      expect(other.text![0], isNot('ג'));
      expect(other.misconception, 'heb.pk.name_length');
    });

    test('a child whose name is in the list is never offered the same name twice', () {
      for (final String name in closedList()) {
        for (int seed = 0; seed < 8; seed++) {
          final Map<String, String> t = texts(
            OwnName(childName: name, random: math.Random(seed)).apply(item('02')),
          );
          expect(t.values.toSet().length, 3, reason: '$name: $t');
          expect(t.values.where((String s) => s == name), hasLength(1));
        }
      }
    });

    test('a long name takes the nearest length from the list; a name no other starts like takes the look-alike letter\'s', () {
      final Map<String, String> long = texts(OwnName(childName: 'אלכסנדר').apply(item('02')));
      expect(long.values, contains('אלכסנדר'));
      expect(long.values.where((String s) => s != 'אלכסנדר' && s.length >= 4), isNotEmpty);
      // no name of the list starts with ך or ם; a name starting with ש has the list's שירה and שקד
      final TapAnswerActivity unusual = OwnName(childName: 'ךךך').apply(item('02')) as TapAnswerActivity;
      expect(
        unusual.options.map((ChoiceOption o) => o.text),
        isNot(contains('ךךך')),
        reason: 'not a name: the companion\'s stands in',
      );
    });

    test('the same name at the same seed gives the same options (a replayed lesson does not change under the child)', () {
      expect(
        texts(OwnName(childName: 'נועה', random: math.Random(3)).apply(item('02'))),
        texts(OwnName(childName: 'נועה', random: math.Random(3)).apply(item('02'))),
      );
    });
  });

  group('a row of letters (A-11.3)', () {
    test('the first letter, its look-alike and the last letter of the name', () {
      final TapAnswerActivity a = OwnName(childName: 'בנימין').apply(item('03')) as TapAnswerActivity;
      final Map<String, String> t = texts(a);
      expect(t[a.correctId], 'ב', reason: 'the right letter is the first, the rightmost');
      expect(t.values.toSet(), <String>{'ב', 'כ', 'ן'});
      expect(a.letterFace, isTrue);
      final ChoiceOption look = a.options.firstWhere((ChoiceOption o) => o.text == 'כ');
      expect(look.misconception, 'heb.pk.shape_bk', reason: 'the tag of the pair, found at run time');
      expect(a.options.firstWhere((ChoiceOption o) => o.text == 'ן').misconception, 'heb.pk.order');
    });

    test('every look-alike pair works both ways', () {
      for (final (String first, String partner, String tag) in <(String, String, String)>[
        ('דנה', 'ר', 'shape_dr'),
        ('חיים', 'ה', 'shape_hxt'),
        ('זהר', 'ו', 'shape_vzn'),
        ('צליל', 'ע', 'shape_az'),
        ('נועה', 'ג', 'shape_gn'),
        ('מיכל', 'ט', 'shape_tm'),
        ('סתיו', 'ם', 'shape_sm'),
      ]) {
        final TapAnswerActivity a = OwnName(childName: first).apply(item('03')) as TapAnswerActivity;
        final ChoiceOption look = a.options.firstWhere((ChoiceOption o) => o.text == partner);
        expect(look.misconception, 'heb.pk.$tag', reason: first);
      }
    });

    test('a name whose last letter is its first or its look-alike, or with no look-alike, uses the companion\'s name', () {
      // דר: the last letter is the look-alike of the first. אבא: no look-alike for א. ניצי is the companion.
      for (final String name in <String>['דר', 'אבא', 'ששש']) {
        final Map<String, String> t = texts(
          OwnName(childName: name, companionName: 'נועה').apply(item('03')),
        );
        expect(t.values.toSet(), <String>{'נ', 'ג', 'ה'}, reason: name);
      }
    });

    test('with no name set the companion\'s stands in, and with neither the house character\'s', () {
      expect(texts(OwnName(companionName: 'טל').apply(item('02'))).values, contains('טל'));
      final Map<String, String> house = texts(OwnName().apply(item('02')));
      expect(house.values, contains(houseName));
      expect(houseName, 'ניצי');
      expect(texts(OwnName().apply(item('03'))).values.toSet(), <String>{'נ', 'ג', 'י'});
    });
  });

  group('the item in the pack', () {
    test('holds the rules and the closed list, and no name of anyone: no option has a text', () {
      for (final String id in <String>['01', '02', '03', '04', '05']) {
        final TapAnswerActivity a = item(id);
        expect(a.ownName, isTrue);
        for (final ChoiceOption o in a.options) {
          expect(o.text, isNull, reason: 'heb.a11.$id: the options are made on the device');
          expect(o.clip, isNull, reason: 'a name is never voiced');
          expect(o.sprite, isNull);
        }
        expect(a.voiceAnswer, isFalse, reason: 'a name is never spoken to the phone either');
      }
      expect(closedList(), hasLength(52));
      expect(closedList().toSet().length, 52);
      expect(
        closedList(),
        containsAll(<String>['ניצי', 'נקודי', 'גוני', 'קובי', 'טימי', 'צעדון', 'פנינה', 'נוגה', 'איתן']),
      );
    });

    test('A-11.4 is the transfer check in the display face, A-11.5 a letter row after a day away', () {
      expect(item('04').displayFont, isTrue);
      expect(item('04').purpose, 'check');
      expect(item('05').purpose, 'check');
      expect(item('01').displayFont, isFalse);
    });

    test('the engine knows the tags of the pairs (a touch on a look-alike is evidence for its own tag)', () {
      expect(
        item('03').engineTags,
        containsAll(<String>['heb.pk.shape_bk', 'heb.pk.shape_gn', 'heb.pk.order']),
      );
    });

    test('an item opened with no personaliser still has faces to draw', () {
      final LessonController c = LessonController(
        content: heb,
        lesson: heb.lessons['heb.name-1']!,
        profileId: 'kid',
        record: (AttemptRecord r) async {},
      );
      for (final Activity a in c.items) {
        expect((a as TapAnswerActivity).ownName, isFalse);
        expect(a.options.every((ChoiceOption o) => o.text != null), isTrue);
      }
      c.dispose();
    });
  });

  group('the name stays on the phone', () {
    test('an answer is recorded as the id of the option, with no name in any field of the row', () async {
      final List<AttemptRecord> rows = <AttemptRecord>[];
      final LessonController c = LessonController(
        content: heb,
        lesson: heb.lessons['heb.name-1']!,
        profileId: 'kid',
        record: (AttemptRecord r) async => rows.add(r),
        personalise: OwnName(childName: 'נועה', companionName: 'ניצי').apply,
      );
      final TapAnswerActivity a = c.current as TapAnswerActivity;
      final String wrong = a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id;
      await c.chooseOption(wrong);
      await c.chooseOption(a.correctId);
      expect(rows, isNotEmpty);
      for (final AttemptRecord r in rows) {
        // every field of the row, so that a field added later is not forgotten here
        final String all = <Object?>[
          r.at.toIso8601String(),
          r.profileId,
          r.packId,
          r.packVersion,
          r.lessonId,
          r.activityId,
          r.activityRevision,
          r.template,
          r.templateVersion,
          r.skillId,
          r.result,
          r.attemptNo,
          r.hintLevel,
          r.misconceptionTag,
          r.response,
          r.durationMs,
          r.sessionId,
          r.input,
        ].join(' ');
        expect(_hebrewLetter.hasMatch(all), isFalse, reason: 'no Hebrew text, so no name, in a row: $all');
        expect(r.response, matches(RegExp(r'^o[0-9]$')));
        // what the tutor is told of an attempt is made from the same row (the controller's `_recent`): ids and enums only
        final TutorAttempt told = TutorAttempt(
          ResponseCode.tutorOption(r.response),
          r.result,
          misconception: r.misconceptionTag.isEmpty ? null : r.misconceptionTag,
        );
        expect(
          _hebrewLetter.hasMatch(jsonEncode(told.toJson())),
          isFalse,
          reason: 'no name in ${told.toJson()}',
        );
      }
      c.dispose();
    });

    // The two files that touch a name: the rules on plain documents (pure Dart, so the pack tools can run them) and the activity adapter.
    const String docsFile = 'lib/content/own_name_docs.dart';
    const String adapterFile = 'lib/play/name_options.dart';

    List<String> directives(String path) => <String>[
      for (final String l in File(path).readAsLinesSync())
        if (RegExp(r'^\s*(import|export|part)\s').hasMatch(l)) l.trim(),
    ];

    test('the code that makes the options imports only what it needs: a closed list of libraries', () {
      const String why =
          'a new import (a log, a store, a network) in a file that holds a name needs the security-engineer';
      expect(directives(docsFile), <String>[
        "import 'dart:convert';",
        "import 'dart:math' as math;",
        "import '../data/child_name.dart' show displayChildName;",
        "import '../strings/he.dart';",
      ], reason: why);
      expect(directives(adapterFile), <String>[
        "import 'dart:math' as math;",
        "import '../content/models.dart';",
        "import '../content/own_name_docs.dart';",
        "export '../content/own_name_docs.dart' show houseName, printName;",
      ], reason: why);
    });

    test('the code that makes the options reads nothing but the name it is given and writes it nowhere', () {
      final String source = <String>[
        for (final String path in <String>[docsFile, adapterFile])
          for (final String l in File(path).readAsLinesSync())
            if (!l.trimLeft().startsWith('//')) l,
      ].join('\n');
      for (final String forbidden in <String>[
        'core/log.dart',
        'Log.',
        'print(',
        'debugPrint',
        'sync',
        'net/',
        'http',
        'database',
        'secure',
        'prefs',
        'File(',
        'tutor',
        'voice',
      ]) {
        expect(source.contains(forbidden), isFalse, reason: 'the own-name code must not touch "$forbidden"');
      }
    });

    List<String> importersOf(String file) => <String>[
      for (final FileSystemEntity f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsLinesSync().any(
              (String l) => RegExp(r'^(import|export)\s').hasMatch(l) && l.contains(file),
            ))
          f.path.replaceAll('\\', '/'),
    ]..sort();

    test('the only callers are the lesson screen and the controller\'s fallback', () {
      expect(importersOf('name_options.dart'), <String>[
        'lib/play/lesson_controller.dart',
        'lib/play/lesson_screen.dart',
      ]);
    });

    test('the rules on documents are used by the adapter and by the validator, which runs them with no name at all', () {
      expect(importersOf('own_name_docs.dart'), <String>[
        'lib/content/pack_validation.dart',
        'lib/play/name_options.dart',
      ]);
    });
  });

  group('an item that cannot be made (SEC-BA-3)', () {
    /// The own-name item [id] of the Hebrew pack with its closed list cut to [names], as a pack that was never validated could hold it.
    TapAnswerActivity broken(String id, List<String> names) {
      final TapAnswerActivity a = item(id);
      final Map<String, Object?> doc = jsonDecode(jsonEncode(a.json)) as Map<String, Object?>;
      (doc['answer']! as Map<String, Object?>)['names'] = names;
      return Activity.fromJson(doc, a.assets) as TapAnswerActivity;
    }

    test('even the house name gives nothing: the item comes back as it was, and never throws', () {
      for (final String? name in <String?>[null, 'נועה', 'ךךך']) {
        final Activity made = OwnName(childName: name).apply(broken('02', <String>[houseName]));
        expect(
          OwnName.stillToMake(made),
          isTrue,
          reason: 'the item cannot be drawn, so the lesson passes it over',
        );
      }
      final TapAnswerActivity three = item('03');
      final Activity junk = Activity.fromJson(<String, Object?>{
        ...three.json,
        'answer': <String, Object?>{
          ...(three.json['answer']! as Map<String, Object?>),
          'pairs': 'not a list',
        },
      }, three.assets);
      expect(() => OwnName().apply(junk), returnsNormally);
    });

    test('the validator runs the house name on every own-name item and says which cannot be made', () async {
      final Directory dir = Directory.systemTemp.createTempSync('nn_own_name_');
      addTearDown(() => dir.deleteSync(recursive: true));
      for (final FileSystemEntity e in languageSource('heb', _languages).listSync()) {
        if (e is File) e.copySync('${dir.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
      }
      final File f = File('${dir.path}${Platform.pathSeparator}activity.heb.a11.02.json');
      final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      // no name starts like the house character's (nun) or like its look-alike letter (gimel): the rules give it no NAME-FIRST option
      final Map<String, Object?> answer = doc['answer']! as Map<String, Object?>;
      answer['names'] = <String>[
        for (final String n in (answer['names']! as List<Object?>).cast<String>())
          if (!n.startsWith('נ') && !n.startsWith('ג')) n,
      ];
      f.writeAsStringSync(jsonEncode(doc));
      String problems = '';
      try {
        await buildPack(dir, await newTestKey());
      } on BuildFailed catch (e) {
        problems = e.problems.join('\n');
      }
      expect(problems, contains('house character'));
      expect(problems, contains('activity.heb.a11.02.json'));
    });
  });

  group('on the screen', () {
    for (final MapEntry<String, Size> b in boards.entries.where(
      (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'tabletLandscape',
    )) {
      testWidgets('the child\'s name is on a tile, as it is printed, on the ${b.key} board', (
        WidgetTester t,
      ) async {
        final Set<String> refs = <String>{};
        void scan(Object? x) {
          if (x is String && x.startsWith('vo:')) refs.add(x);
          if (x is Map<String, Object?>) x.values.forEach(scan);
          if (x is List<Object?>) x.forEach(scan);
        }

        scan(pack.docs);
        final AppRig rig = AppRig(
          content: heb,
          characters: await languageVoiceSource(refs),
          player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
        )..languagePacks = <String, PackContent>{'heb': heb};
        await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
        await rig.db.putSetting(
          languagesSettingKey,
          const FamilyLanguages().withSwitches(langKid, 'heb', const LanguageSwitches(on: true))!.encode(),
        );
        await rig.pump(t, size: b.value);
        await t.tap(find.text('נֹעָה'));
        await t.pumpAndSettle();
        t
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(
              MaterialPageRoute<void>(
                builder: (BuildContext c) =>
                    const LessonScreen(profileId: langKid, course: 'heb', lessonId: 'heb.name-1'),
              ),
            );
        await t.pump(const Duration(milliseconds: 600));
        await waitFor(t, 2200);
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        // the first item is the guided step: the child's name, printed without nikud, and one other name
        expect(find.text('נעה'), findsOneWidget);
        expect(find.text('נֹעָה'), findsNothing, reason: 'the name on a tile is printed with no nikud');
        await t.pumpWidget(const SizedBox());
      });
    }
  });

  test('the closed list is what the teacher wrote: 52 names of two to five letters', () {
    final List<Object?> names =
        jsonDecode(
              File('../content/languages/heb/pack/activity.heb.a11.02.json').readAsStringSync(),
            )['answer']['names']!
            as List<Object?>;
    expect(names, hasLength(52));
    for (final Object? n in names) {
      expect((n! as String).length, inInclusiveRange(2, 5));
    }
  });
}
